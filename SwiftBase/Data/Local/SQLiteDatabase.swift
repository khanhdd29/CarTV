//
//  SQLiteDatabase.swift
//  SwiftBase
//
//  Thin wrapper over the system `libsqlite3` (import SQLite3) — no third-party
//  dependency, FTS5 available out of the box on iOS. Not thread-safe by itself;
//  `IPTVStore` is an actor and owns the single connection, so all access is
//  serialized (spec §Driver 1: SQLite with index, never the full list in RAM).
//

import Foundation
import SQLite3

/// SQLite asks callers to say whether a bound blob/text is static or transient.
/// `SQLITE_TRANSIENT` tells SQLite to copy the bytes, which is what we want for
/// Swift `String`s whose storage may move.
private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

final class SQLiteDatabase {
    private var handle: OpaquePointer?

    var errorMessage: String {
        if let msg = sqlite3_errmsg(handle) { return String(cString: msg) }
        return "unknown sqlite error"
    }

    init(path: String) throws {
        if sqlite3_open(path, &handle) != SQLITE_OK {
            let message = errorMessage
            sqlite3_close(handle)
            handle = nil
            throw AppError.storage(underlying: message)
        }
        // Pragmas tuned for a large, mostly-read catalogue.
        exec("PRAGMA journal_mode = WAL;")
        exec("PRAGMA synchronous = NORMAL;")
        exec("PRAGMA foreign_keys = ON;")
        exec("PRAGMA temp_store = MEMORY;")
    }

    deinit { sqlite3_close(handle) }

    // MARK: - Statement-free execution

    @discardableResult
    func exec(_ sql: String) -> Bool {
        sqlite3_exec(handle, sql, nil, nil, nil) == SQLITE_OK
    }

    // MARK: - Prepared statements

    /// Prepare a statement; caller must `finalize` it.
    func prepare(_ sql: String) throws -> Statement {
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(handle, sql, -1, &stmt, nil) == SQLITE_OK, let stmt else {
            throw AppError.storage(underlying: errorMessage)
        }
        return Statement(stmt: stmt, db: self)
    }

    func beginTransaction() throws { try run("BEGIN IMMEDIATE TRANSACTION;") }
    func commit() throws { try run("COMMIT;") }
    func rollback() { exec("ROLLBACK;") }

    /// Run a one-shot statement with optional binds, ignoring any rows.
    func run(_ sql: String, _ binds: [SQLValue] = []) throws {
        let stmt = try prepare(sql)
        defer { stmt.finalize() }
        stmt.bind(binds)
        try stmt.stepDone()
    }

    func lastInsertRowId() -> Int64 { sqlite3_last_insert_rowid(handle) }
}

// MARK: - Bindable value

enum SQLValue {
    case text(String)
    case int(Int64)
    case double(Double)
    case null
}

// MARK: - Statement

final class Statement {
    private let stmt: OpaquePointer
    private unowned let db: SQLiteDatabase

    init(stmt: OpaquePointer, db: SQLiteDatabase) {
        self.stmt = stmt
        self.db = db
    }

    func finalize() { sqlite3_finalize(stmt) }
    func reset() { sqlite3_reset(stmt); sqlite3_clear_bindings(stmt) }

    func bind(_ values: [SQLValue]) {
        for (i, value) in values.enumerated() {
            bind(value, at: Int32(i + 1))
        }
    }

    func bind(_ value: SQLValue, at index: Int32) {
        switch value {
        case .text(let s):   sqlite3_bind_text(stmt, index, s, -1, SQLITE_TRANSIENT)
        case .int(let n):    sqlite3_bind_int64(stmt, index, n)
        case .double(let d): sqlite3_bind_double(stmt, index, d)
        case .null:          sqlite3_bind_null(stmt, index)
        }
    }

    /// Step a statement expected to return no rows (INSERT/UPDATE/DELETE/DDL).
    func stepDone() throws {
        let rc = sqlite3_step(stmt)
        guard rc == SQLITE_DONE || rc == SQLITE_ROW else {
            throw AppError.storage(underlying: db.errorMessage)
        }
    }

    /// Step once; returns `true` while a row is available.
    func stepRow() -> Bool {
        sqlite3_step(stmt) == SQLITE_ROW
    }

    // MARK: Column readers (0-based)

    func int(_ col: Int32) -> Int64 { sqlite3_column_int64(stmt, col) }
    func double(_ col: Int32) -> Double { sqlite3_column_double(stmt, col) }

    func string(_ col: Int32) -> String? {
        guard let c = sqlite3_column_text(stmt, col) else { return nil }
        return String(cString: c)
    }
}
