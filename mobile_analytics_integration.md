# Mobile Analytics Integration Guide — Finishd Platform

This document outlines the steps for a mobile developer or agent to wire up user interaction tracking in the mobile application. Wiring this up ensures that the Admin Panel's **Platform Analytics** dashboard receives real-time metrics (Active Users, Video Completion, Scroll Depth, and Community Engagement).

---

## 1. Tracking Daily Active Users (DAU) & Video Interactions

The admin dashboard RPC `get_daily_active_users` computes active users by checking:
1. Entries in the `video_interactions` table updated today.
2. Entries in the `analytics_events` table created today.

### Implementation Steps (Mobile Client):
1. **On Video View/Interaction**: Whenever a user scrolls onto, clicks, or plays a video in the mobile feed, insert/upsert a record in the `video_interactions` table.
2. **Code Snippet (Flutter Mobile)**:
   ```dart
   import 'package:supabase_flutter/supabase_flutter.dart';

   Future<void> logVideoInteraction(String videoId) async {
     final supabase = Supabase.instance.client;
     final userId = supabase.auth.currentUser?.id;
     
     if (userId == null) return;

     try {
       await supabase.from('video_interactions').upsert({
         'user_id': userId,
         'video_id': videoId,
         'updated_at': DateTime.now().toIso8601String(),
       });
     } catch (e) {
       print('Error logging video interaction: $e');
     }
   }
   ```

---

## 2. Tracking Scroll Depth Metrics

The Platform Analytics dashboard aggregates average scroll depth using events named `'scroll_depth'` from the `analytics_events` table.

### Implementation Steps (Mobile Client):
1. **On Scroll Listener**: Add a scroll listener to feed lists (e.g., Home feed, Community feed).
2. **Throttled Events Logging**: To prevent spamming the database, trigger an analytics log only when the user reaches incremental scroll thresholds (e.g., every 500px of vertical scrolling or when they change pages, throttled to at most once per 5 seconds).
3. **Code Snippet (Flutter Mobile)**:
   ```dart
   import 'package:flutter/material.dart';
   import 'package:supabase_flutter/supabase_flutter.dart';

   class FeedScrollTracker extends StatelessWidget {
     final ScrollController _scrollController = ScrollController();
     double _maxLoggedDepth = 0.0;

     void _onScroll() {
       final currentPixels = _scrollController.position.pixels;
       
       // Log scroll depth in 500px increments
       if (currentPixels > _maxLoggedDepth + 500) {
         _maxLoggedDepth = (currentPixels / 500).floor() * 500.0;
         _logScrollDepthEvent(_maxLoggedDepth);
       }
     }

     Future<void> _logScrollDepthEvent(double depthPx) async {
       final supabase = Supabase.instance.client;
       final userId = supabase.auth.currentUser?.id;

       try {
         await supabase.from('analytics_events').insert({
           'user_id': userId, // Can be null if anonymous
           'event_name': 'scroll_depth',
           'parameters': {
             'depth_px': depthPx,
             'screen': 'feed_for_you',
           },
         });
       } catch (e) {
         print('Failed to log scroll depth: $e');
       }
     }

     @override
     Widget build(BuildContext context) {
       return NotificationListener<ScrollNotification>(
         onNotification: (notification) {
           _onScroll();
           return true;
         },
         child: ListView.builder(
           controller: _scrollController,
           itemBuilder: (context, index) => VideoCard(),
         ),
       );
     }
   }
   ```

---

## 3. Tracking Community Engagement

The Platform Analytics dashboard aggregates engagement per day from three real-time tables:
- `community_posts` (inserts where `created_at` matches the date).
- `community_comments` (inserts where `created_at` matches the date).
- `community_members` (inserts where `joined_at` matches the date).

### Implementation Steps (Mobile Client):
Ensure that every time a user creates a post, posts a comment, or joins a community, the client issues the standard insert:
```dart
// 1. When posting inside a Community:
await supabase.from('community_posts').insert({
  'community_id': communityId,
  'author_id': currentUserId,
  'content': postContentText,
});

// 2. When commenting on a Community Post:
await supabase.from('community_comments').insert({
  'post_id': postId,
  'author_id': currentUserId,
  'content': commentText,
});

// 3. When joining a Community:
await supabase.from('community_members').insert({
  'community_id': communityId,
  'user_id': currentUserId,
});
```

---

## 4. Alternative: Aggregate Event Tracking Edge Function

Instead of making direct SQL inserts from the client, you can deploy a centralized Edge Function. This is recommended to decouple client code and run validations.

### Edge Function Template (`supabase/functions/track-interaction/index.ts`):
```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

serve(async (req) => {
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_ANON_KEY')!,
    { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
  )

  const { eventName, parameters } = await req.json()
  const { data: { user } } = await supabase.auth.getUser()

  if (eventName === 'scroll_depth') {
    await supabase.from('analytics_events').insert({
      user_id: user?.id,
      event_name: 'scroll_depth',
      parameters
    })
  }

  return new Response(JSON.stringify({ success: true }), {
    headers: { 'Content-Type': 'application/json' }
  })
})
```
Invoke it from the mobile app via:
```dart
await supabase.functions.invoke('track-interaction', body: {
  'eventName': 'scroll_depth',
  'parameters': {'depth_px': scrollPixels},
});
```
