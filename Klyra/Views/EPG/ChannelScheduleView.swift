//
//  ChannelScheduleView.swift
//  SwiftBase
//
//  The full EPG timeline for one channel — the day's programmes with times, the
//  one on now highlighted. Opened by tapping the now/next strip on the player.
//

import SwiftUI
import Factory

struct ChannelScheduleView: View {
    let channel: Channel
    let onClose: () -> Void

    @Injected(\.epgRepository) private var epg: EPGRepository
    @State private var items: [EPGEntry] = []
    @State private var loaded = false
    @State private var reminders: Set<String> = []

    var body: some View {
        VStack(spacing: 0) {
            header
            if loaded && items.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(items, id: \.self) { row($0) }
                    }
                    .padding(16)
                    .padding(.bottom, 30)
                }
                .scrollIndicators(.hidden)
            }
        }
        .cinematicBackground()
        .onAppear {
            Task { items = await epg.schedule(for: channel); loaded = true }
            Task { reminders = await ReminderManager.pendingIDs() }
        }
    }

    private func reminderID(_ entry: EPGEntry) -> String {
        "epg.\(channel.streamURL).\(Int(entry.start.timeIntervalSince1970))"
    }

    private func toggleReminder(_ entry: EPGEntry) {
        let id = reminderID(entry)
        if reminders.contains(id) {
            ReminderManager.cancel(id: id)
            reminders.remove(id)
        } else {
            Task {
                guard await ReminderManager.requestAuth() else { return }
                let fire = entry.start.addingTimeInterval(-120)
                ReminderManager.schedule(
                    id: id, title: channel.name,
                    body: String(format: "epg_reminder_body".localized, entry.title),
                    at: fire > Date() ? fire : entry.start)
                reminders.insert(id)
            }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("epg_title".localized)
                    .font(.caption.weight(.heavy)).tracking(1.5).foregroundStyle(AppColors.secondary)
                Text(channel.name).font(.title3.weight(.bold)).foregroundStyle(AppColors.textPrimary).lineLimit(1)
            }
            Spacer()
            Button(action: onClose) {
                Image(systemName: "xmark").font(.body.weight(.semibold)).foregroundStyle(.white)
                    .padding(10).background(.black.opacity(0.4), in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(16)
    }

    private func row(_ entry: EPGEntry) -> some View {
        let isNow = Date() >= entry.start && Date() < entry.stop
        return HStack(alignment: .top, spacing: 14) {
            Text(clock(entry.start))
                .font(.subheadline.monospacedDigit().weight(.semibold))
                .foregroundStyle(isNow ? AppColors.secondary : AppColors.textSecondary)
                .frame(width: 58, alignment: .leading)
            VStack(alignment: .leading, spacing: 6) {
                Text(entry.title)
                    .font(.subheadline.weight(isNow ? .bold : .medium))
                    .foregroundStyle(AppColors.textPrimary)
                if isNow {
                    HStack(spacing: 8) {
                        Text("epg_now".localized)
                            .font(.caption2.weight(.heavy)).foregroundStyle(AppColors.secondary)
                        ProgressView(value: entry.progress())
                            .tint(AppColors.secondary).scaleEffect(x: 1, y: 0.6, anchor: .center)
                    }
                }
            }
            Spacer(minLength: 0)
            if entry.start > Date() {
                Button { toggleReminder(entry) } label: {
                    let on = reminders.contains(reminderID(entry))
                    Image(systemName: on ? "bell.fill" : "bell")
                        .font(.subheadline)
                        .foregroundStyle(on ? AppColors.secondary : AppColors.textTertiary)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(isNow ? AppColors.primary.opacity(0.14) : AppColors.surface.opacity(0.6))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isNow ? AppColors.secondary.opacity(0.5) : AppColors.border, lineWidth: 1))
        )
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 40)).foregroundStyle(AppColors.textTertiary)
            Text("epg_schedule_empty".localized)
                .font(.subheadline).foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center).padding(.horizontal, 36)
            Spacer(); Spacer()
        }
    }

    private func clock(_ date: Date) -> String {
        let f = DateFormatter(); f.timeStyle = .short; f.dateStyle = .none
        return f.string(from: date)
    }
}
