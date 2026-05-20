# tekisa

Plateforme Tekisa (commerce, ventes, stock, fournisseurs) — Flutter + Django.

## Structure

- `lib/` — application Flutter principale
- `backend/` — API Django
- `assets/` — images et ressources
- `android/`, `ios/`, `web/` — cibles Flutter

## Backend (dev local)

```bash
cd backend
pip install -r requirements.txt
python manage.py runserver
```

## Mobile (Flutter)

```bash
flutter pub get
flutter run
```
