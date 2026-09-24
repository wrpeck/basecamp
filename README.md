# Basecamp

A Flutter app for planning camping trips, previewed on a phone with Shorebird Zap.

- **Overview:** trip dates and countdown, campsite and site number, address, check-in and check-out times, reservation number, ranger phone, GPS coordinates (copy them or open directions), parking, costs with a per-person split, and notes.
- **Meals:** a meal plan for each day with cooks and ingredients, plus a shopping list built from those ingredients.
- **Gear:** a packing checklist grouped by category, with quantities and who's bringing each item.
- **Plans:** a timeline of hikes, day trips and activities for each day.
- **Crew:** each camper's contact info with tap-to-call, text and email buttons, plus their role, emergency contact and notes.

Data is saved on the device. The app includes a sample trip.

```sh
flutter run -d chrome        # develop
flutter build web --release  # build the Zap payload (zip the contents of build/web)
```
