# NexusProbe - Design System

**Version:** 1.2  
**Last Updated:** July 19, 2026  
**Theme:** Dark, professional, modern OSINT dashboard

---

## 1. Color Palette

### Core Colors (Dark Theme)
| Token              | Hex       | Usage |
|--------------------|-----------|-------|
| Background         | `#0B0F19` | Main page background |
| Surface / Card     | `#111827` | Cards, panels |
| Surface Elevated   | `#1F2937` | Hover / elevated cards |
| Border             | `#1F2937` / `#374151` | Subtle borders |
| Primary            | `#3B82F6` | Buttons, links, accents |
| Primary Hover      | `#2563EB` | |
| Success / Active   | `#10B981` | Active status badges |
| Warning            | `#F59E0B` | Medium risk |
| Danger / High Risk | `#EF4444` | High risk score |
| Text Primary       | `#F9FAFB` | Main headings |
| Text Secondary     | `#9CA3AF` | Descriptions, meta |
| Text Muted         | `#6B7280` | Placeholders |

### Accent Colors for Platforms
- GitHub: `#24292F` / white
- Google: Multi-color (official)
- Adobe: `#FF0000`
- Microsoft: `#00A4EF`
- Spotify: `#1DB954`
- X/Twitter: `#FFFFFF` on dark

---

## 2. Typography

- **Font Family:** Inter (or system-ui / Geist Sans)
- **Headings:** font-bold / font-semibold
- **Body:** font-normal, text-sm / text-base
- **Mono:** font-mono for usernames, IDs, emails

### Scale
- H1: 2xl – 3xl
- H2: xl – 2xl
- Card Title: lg
- Body: sm – base
- Meta / labels: xs – sm

---

## 3. Component Style

### Cards
- Rounded: `rounded-xl` or `rounded-2xl`
- Border: subtle `border border-border`
- Hover: `hover:border-primary/50 transition-all`
- Padding: generous (p-5 / p-6)
- Shadow: soft or none (glass-like preferred)

### Account Cards
- Avatar (left) + Title + Badge (right)
- Status badge always visible (“Active”)
- Optional details grid (category, followers, etc.)
- Action button: “View Profile” with external link icon

### Profile Photos Grid
- 4–6 columns on desktop
- Rounded squares / circles
- Hover scale effect
- Fallback icon when no photo

### Risk Score
- Large radial / circular gauge
- Color transitions: green → yellow → red
- Numeric score + label (Low / Medium / High / Critical)

---

## 4. Layout Principles
- Max width: `max-w-6xl` or `max-w-7xl` centered
- Consistent spacing: `space-y-6` / `space-y-8`
- Responsive grid: 1 → 2 → 3 columns for cards
- Sticky header optional
- Clear visual hierarchy: Risk → Photos → Accounts → Details

---

## 5. Icons
- Lucide React for general icons
- Font Awesome brands for platform logos (Spotify, Adobe, etc.)
- Custom SVG for GitHub, X when needed

---

## 6. Motion
- Subtle transitions only (200–300ms)
- Loading skeletons matching card layout
- No distracting animations

---

## 7. Accessibility
- Sufficient contrast
- Focus rings on interactive elements
- Alt text on all avatars
- Semantic HTML

---

**Reference Screenshots:** Dark navy cards, glass-like surfaces, platform icons, clean typography (as provided in project discussions).

---

**Next Document:** Memory.md
