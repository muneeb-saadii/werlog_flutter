# Werlog — Flutter UI

## File structure

```
lib/
├── main.dart                          ← App entry + simple demo navigator
├── theme/
│   └── app_theme.dart                 ← WerlogColors · WerlogTextStyles · WerlogTheme
├── models/
│   └── app_models.dart                ← All data classes (UserData, DashboardStats, …)
├── widgets/
│   └── shared_widgets.dart            ← Reusable components used across screens
└── screens/
    ├── screen_01_welcome.dart          ← 01 · Welcome / splash (mobile_01 screen 1)
    ├── screen_02_auth.dart             ← 02 · Sign in  +  03 · Email verify
    ├── screen_03_subscription.dart    ← 04 · Pick a plan  +  05 · Checkout
    └── screen_06_dashboard.dart        ← 06 · Customer Dashboard
```

## How to run

```bash
flutter pub get
flutter run
```

The demo navigator walks through all 6 screens in order; tap the
primary button to advance, back arrow to go back.

---

## Updating screen data (variables)

Every screen has a dedicated **data class**. Populate it from your API
and pass it to the screen widget — the UI rebuilds automatically.

### Welcome screen
```dart
WelcomeScreen(
  data: WelcomeScreenData(
    appName:        'WERLOG',
    headlinePlain:  'Every receipt,\norganized in ',
    headlineAccent: 'seconds',
    subtitle:       'Snap, scan, and save...',
    primaryCTA:     'Get started free',
    secondaryCTA:   'I already have an account',
  ),
)
```

### Sign-in screen
```dart
SignInScreen(
  initialData: SignInScreenData(
    emailValue:    'user@example.com',
    isSignIn:      true,
  ),
)
```

### Email verify screen
```dart
EmailVerifyScreen(
  data: EmailVerifyScreenData(
    email:       'user@example.com',
    digits:      ['', '', '', '', '', ''],  // fill on success
    resendLabel: "Didn't get it? Resend in 23s",
  ),
)
```

### Subscription plans screen
```dart
SubscriptionScreen(
  plans: myPlansFromApi,          // List<SubscriptionPlan>
  initialSelectedIndex: 1,        // 0 = Free, 1 = Pro, 2 = Basic
  initialCycle: 1,                // 0 = Monthly, 1 = Yearly
)
```

### Checkout screen
```dart
CheckoutScreen(
  data: CheckoutData(
    planDisplayName: 'Pro · Yearly',
    priceLabel:      '\$276',
    pricePeriod:     '/year',
    cardBrand:       'VISA',
    cardLast4:       '4242',
    dueAfterTrial:   '\$276.00',
  ),
)
```

### Customer Dashboard
```dart
CustomerDashboardScreen(
  user:  UserData(name: 'Ahmed', plan: 'PRO'),
  stats: DashboardStats(
    totalTracked:  'Rs 42,870',
    scansUsed:     42,
    scansTotal:    1000,
    expenseAmount: 'Rs 612',
    expenseCount:  9,
    warrantyAmount: 'Rs 1,299',
    warrantyCount:  3,
  ),
  alert: WarrantyAlert(
    title:    'Warranty expiring in 7 days',
    subtitle: 'Dell Monitor XU27 · May 24, 2026',
  ),
  transactions: myTransactionList,
)
```

---

## Color / Theme changes

All colours live in `WerlogColors`. Change one constant and every
widget that references it updates automatically.

All text styles are in `WerlogTextStyles`. All use `DM Sans` via
`google_fonts`. Change the font family in one place there to roll out
a new typeface globally.

`WerlogTheme.light` is the `ThemeData` passed to `MaterialApp`. A
`WerlogTheme.dark` variant can be added there following the same
pattern.
