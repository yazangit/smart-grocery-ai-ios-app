# Smart Grocery — Integrated Native iOS App

This package merges the native SwiftUI/Firebase iOS app with the missing feature set from the web prototype.

## Integrated features

- Firebase Auth login
- Firestore grocery lists and items
- Add/delete grocery lists
- Add/delete/toggle grocery items
- Generated weekly list from repeated bought items
- Receipt OCR using Apple Vision
- Shopping session history and monthly stats
- Budget tab with monthly budget, spending progress, manual spending, and open basket estimate
- AI Assistant tab with recipe recommendations and one-tap ingredient import
- Preferred shops management
- Shops tab with Augsburg/Munich supermarket suggestions and Apple Maps handoff
- Settings tab with language/currency/budget preferences and sign out

## Important Firebase step

`Resources/GoogleService-Info.plist` is currently a placeholder so the Xcode project structure stays complete.
Replace it with your real Firebase file from Firebase Console before running the app with real Auth/Firestore.

## Open in Xcode

1. Unzip this folder.
2. Open `Smart_Grocery.xcodeproj`.
3. Replace `Resources/GoogleService-Info.plist` with your real Firebase file.
4. In Xcode, check Signing & Capabilities.
5. Run on simulator or iPhone.

## Notes

- The Gemini/Geoapify server APIs from the Next.js prototype were converted into native offline demo logic because API keys should not be hardcoded inside an iOS app.
- For production AI recipes or live nearby-shop search, add a small backend such as Firebase Functions, Cloud Run, or your existing Next.js API and call it from Swift using URLSession.
