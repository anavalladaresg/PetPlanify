import SwiftUI

struct DashboardCard: View {
    let title: LocalizedStringKey
    let value: String
    let detail: LocalizedStringKey?
    let symbol: String
    var accent: Color = AppTheme.green
    let identifier: String

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(alignment: .top) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryInk)
                Spacer(minLength: 8)
                Image(systemName: symbol)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(accent)
                    .frame(width: 30, height: 30)
                    .background(accent.opacity(0.11), in: Circle())
                    .accessibilityHidden(true)
            }

            Text(value)
                .font(.title2.weight(.semibold))
                .foregroundStyle(AppTheme.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.78)

            if let detail {
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryInk)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 108, alignment: .topLeading)
        .padding(17)
        .appSurface()
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(identifier)
    }
}

struct SummaryCard: View {
    let title: LocalizedStringKey
    let value: String
    let symbol: String
    let identifier: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppTheme.green)
                .frame(width: 34, height: 34)
                .background(AppTheme.greenSoft, in: Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryInk)
                Text(value)
                    .font(.headline)
                    .foregroundStyle(AppTheme.ink)
            }
            Spacer(minLength: 0)
        }
        .padding(15)
        .appSurface(cornerRadius: 16)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(identifier)
    }
}

