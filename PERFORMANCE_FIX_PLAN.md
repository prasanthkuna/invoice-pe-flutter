# Performance & Keyboard Fix Plan

## Root Cause Analysis

### 1. **Main Thread Blocking (600+ Skipped Frames)**
- Heavy animations on TextField widgets during initial render
- Multiple animations running simultaneously on phone input screen
- Animations competing with keyboard show animation

### 2. **Keyboard Show Animation Cancellation**
- ImeTracker logs show keyboard animations being cancelled repeatedly
- This happens when the UI thread is blocked during the animation phase
- TextField animations (.animate().fadeIn()) conflict with keyboard animations

### 3. **Performance Bottlenecks**
- Phone input screen has 5 separate animations running on mount:
  - Progress bar: `.animate().scaleX(duration: 800.ms)`
  - Title: `.animate().fadeIn(delay: 200.ms).slideX(begin: -0.3)`
  - Subtitle: `.animate().fadeIn(delay: 400.ms).slideX(begin: -0.3)`
  - Input container: `.animate().fadeIn(delay: 600.ms).slideY(begin: 0.3)`
  - Button: `.animate().fadeIn(delay: 800.ms).slideY(begin: 0.5)`

## Immediate Actions

### Phase 1: Remove Animation Conflicts (Quick Win)

1. **Disable TextField Animations**
   - Remove all `.animate()` calls from input-related widgets
   - This will eliminate animation conflicts with keyboard

2. **Reduce Animation Load**
   - Use simpler animations or remove them temporarily
   - Stagger animations more to reduce concurrent load

### Phase 2: Optimize Main Thread

1. **Profile with Flutter DevTools**
   ```bash
   flutter pub global activate devtools
   flutter pub global run devtools
   ```

2. **Add Performance Monitoring**
   - Add frame timing logs
   - Monitor widget build times

3. **Defer Non-Critical Operations**
   - Move any synchronous operations to isolates
   - Use compute() for heavy computations

### Phase 3: Fix Keyboard Issues

1. **Add Explicit Focus Management**
   - Use FocusNode for TextField
   - Request focus after animations complete

2. **Add Keyboard Visibility Listener**
   - Monitor keyboard state
   - Debug why keyboard fails to show

## Implementation Steps

### Step 1: Create Performance-Optimized Phone Input Screen

```dart
// Remove animations from TextField and reduce animation complexity
```

### Step 2: Add Debugging Tools

```dart
// Add frame callback monitoring
// Add keyboard state monitoring
```

### Step 3: Test & Validate

1. Run app with performance overlay
2. Monitor frame rate during keyboard show
3. Verify keyboard appears consistently

## Expected Outcomes

1. **Immediate**: Keyboard should show without cancellation
2. **Short-term**: Frame rate should stay above 30fps during animations
3. **Long-term**: Smooth UI interactions with no frame drops

## Monitoring Commands

```bash
# Check current performance
flutter analyze --no-fatal-infos

# Run with performance overlay
flutter run --profile

# Monitor frame timing
flutter screenshot --observatory-url=http://127.0.0.1:xxxxx/

# Check for shader compilation jank
flutter run --cache-sksl
```

## Success Metrics

- [ ] Keyboard shows on first tap
- [ ] No "Skipped frames" warnings in logs
- [ ] ImeTracker shows successful keyboard animations
- [ ] Frame rate stays above 30fps during interactions
- [ ] No animation cancellations in logs
