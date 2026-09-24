# Basecamp

A Flutter app for planning camping trips, previewed on a phone with Shorebird Zap.

- **Overview:** trip dates and countdown, campsite and site number, address, check-in and check-out times, reservation number, ranger phone, GPS coordinates (copy them or open directions), parking, costs with a per-person split, and notes.
- **Meals:** a meal plan for each day with cooks and ingredients, plus a shopping list built from those ingredients.
- **Gear:** group gear (who's providing it, who it's for) and your own packing list, with Group, Mine and All views, filters for packed and unclaimed items, and reusable gear lists.
- **Plans:** a timeline of hikes, day trips and activities for each day.
- **Crew:** each camper's contact info with tap-to-call, text and email buttons, plus their role, emergency contact and notes.

Data is saved on the device. The app includes a sample trip.

## Accounts and backend (placeholders)

The account screen (tap the profile icon on the home screen) signs in locally only. To connect real services later:

- `lib/services/auth_service.dart`: implement `AuthService` with a real provider and pass it to `BasecampApp` in `main.dart` instead of `LocalAuthService`.
- `lib/store.dart`: `TripStore` is where trips and gear lists are loaded and saved; replace its persistence with API calls to sync them.

```sh
flutter run -d chrome        # develop
flutter build web --release  # build the Zap payload (zip the contents of build/web)
```
