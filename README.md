# SafeLink Child (iOS pairing prototype)

A native SwiftUI iOS app prototype for a child device to enter a short-lived pairing code and explicitly approve linking that iPhone to the parent device. This project does **not** request microphone permission, capture audio, or stream audio.

## Configuration

- Supabase project URL is set in `ContentView.swift` to the SafeLink project URL.
- On first launch, open the gear icon and enter the project's **publishable** key (`sb_publishable_...` or its current public anon key if that's what the project provides).
- Never use a Supabase secret/service-role key in the app.

## Backend expectation

The app sends `POST /functions/v1/approve-pairing-code` with:

```json
{
  "code": "12_CHARACTER_CODE",
  "child_device_id": "a-persistent-uuid",
  "child_label": "Child iPhone",
  "approved": true
}
```

The Edge Function must validate expiry and one-time use server-side and return `{ "paired": true }` on success. The app does not treat mere code entry as success.

## Build and install notes for Windows-only development

The Swift source must be compiled with Apple's Xcode on macOS. The included GitHub Actions workflow uses a GitHub-hosted macOS runner to build a device-targeted unsigned IPA artifact. A signed build and installation on a physical iPhone are separate steps and require Apple-compatible signing/provisioning; do not upload Apple certificates, passwords, or private keys to a public repo. Apple free Personal Team provisioning commonly expires after 7 days when installed through Xcode.
