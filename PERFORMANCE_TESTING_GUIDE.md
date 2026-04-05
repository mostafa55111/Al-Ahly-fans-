# 🚀 Reels Performance Testing Guide

## 📱 Setup for Performance Testing

### 1. Enable Performance Overlay
The app now includes a performance monitor that shows:
- **Real-time FPS** (frames per second)
- **Average FPS** (over last 100 samples)
- **Min/Max FPS** (performance range)
- **Jank Detection** (frames below 30 FPS)

### 2. How to Use
1. **Run the app** in profile mode:
   ```bash
   flutter run --profile
   ```

2. **Enable overlay**: Tap the green/red speed icon in top-right corner

3. **Scroll through reels**: Quickly swipe through at least 20 reels

4. **Monitor metrics**: Watch for:
   - FPS stability (should stay above 30)
   - Frame drops (red indicators)
   - Memory usage patterns

## 📊 Performance Metrics to Monitor

### ✅ Good Performance
- **FPS**: 55-60 (green indicator 🟢)
- **Jank**: None (NO)
- **Frame drops**: < 5% of total frames
- **Memory**: Stable, no major spikes

### ⚠️ Acceptable Performance  
- **FPS**: 30-55 (yellow indicator 🟡)
- **Jank**: Occasional (rare YES)
- **Frame drops**: 5-15% of total frames
- **Memory**: Minor spikes during video changes

### ❌ Poor Performance
- **FPS**: < 30 (red indicator 🔴)
- **Jank**: Frequent (consistent YES)
- **Frame drops**: > 15% of total frames
- **Memory**: Large spikes, potential leaks

## 🧪 Testing Scenarios

### Scenario 1: Fast Scrolling
```
Test: Rapid vertical scrolling through 20+ reels
Expected: FPS should remain stable above 45
Monitor: Frame drops during quick transitions
```

### Scenario 2: Video Transitions
```
Test: Pause at each reel for 2 seconds, then swipe
Expected: Minimal FPS drop during video switches
Monitor: Memory usage during video initialization
```

### Scenario 3: Cache Performance
```
Test: Scroll back to previously viewed reels
Expected: Instant playback, no loading delay
Monitor: FPS improvement with cached videos
```

### Scenario 4: Memory Stress
```
Test: Scroll back and forth through 50+ reels
Expected: Memory should stabilize, not grow indefinitely
Monitor: Garbage collection patterns
```

## 📈 Expected Results with Optimizations

### Before Optimizations:
- **Average FPS**: 25-35
- **Frame drops**: 20-30%
- **Video loading**: 2-5 seconds
- **Memory usage**: High, potential leaks

### After Optimizations:
- **Average FPS**: 55-60
- **Frame drops**: < 5%
- **Video loading**: < 1 second (cached), 2-3 seconds (new)
- **Memory usage**: Stable, optimized

## 🔍 Debug Information

### Performance Overlay Legend:
- 🟢 **Green**: Excellent (55-60 FPS)
- 🟡 **Yellow**: Good (30-55 FPS)  
- 🔴 **Red**: Poor (< 30 FPS)

### Cache Management:
- **Storage icon** (top-left): Tap to view cache info
- **Cache size**: Should stay under 500MB
- **Active controllers**: Should be max 2

## 📝 Logging Results

### What to Log:
1. **Average FPS** during normal scrolling
2. **Minimum FPS** during video transitions
3. **Number of jank events** in 20-reel test
4. **Memory usage patterns** (growing/stable)
5. **Cache hit rate** (instant vs delayed playback)

### Example Log Entry:
```
Test Run: 2025-03-30 12:45
- Average FPS: 57.2
- Min FPS: 42.1 (during video switches)
- Max FPS: 60.0
- Jank events: 2/20 reels (10%)
- Memory: Stable, no leaks detected
- Cache hit rate: 85% (17/20 reels cached)
```

## 🎯 Performance Targets

### Primary Goals:
- ✅ **60 FPS target** during smooth scrolling
- ✅ **< 5% jank rate** across all scenarios
- ✅ **< 1 second video loading** for cached content
- ✅ **Stable memory usage** with no leaks

### Secondary Goals:
- ✅ **Smooth transitions** between videos
- ✅ **Responsive UI** with no blocking
- ✅ **Efficient caching** with good hit rates
- ✅ **Optimized state management** with minimal rebuilds

## 🚨 Troubleshooting

### If FPS is consistently low:
1. Check video player initialization
2. Verify cache manager is working
3. Look for memory leaks in controllers
4. Check for unnecessary widget rebuilds

### If memory is growing:
1. Ensure video controllers are being disposed
2. Verify cache size limits are enforced
3. Check for circular references in bloc
4. Monitor garbage collection frequency

### If jank is frequent:
1. Optimize video preloading timing
2. Reduce heavy operations on main thread
3. Check for blocking I/O operations
4. Verify state update efficiency

## 📱 Device Testing

### Recommended Test Devices:
- **High-end**: 60 FPS target
- **Mid-range**: 45-55 FPS acceptable
- **Low-end**: 30+ FPS minimum acceptable

### Network Conditions:
- **WiFi**: Test with full caching
- **4G**: Test with moderate caching
- **3G**: Test with limited caching

---

**Note**: Performance monitoring is now built into the app. Use the overlay to get real-time metrics during testing!
