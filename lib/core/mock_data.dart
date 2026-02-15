import 'dart:math';

class MockData {
  static final Random _random = Random();

  static List<int> generateChartData(int length, {int max = 100}) {
    return List.generate(length, (index) => _random.nextInt(max));
  }

  static const List<Map<String, dynamic>> users = [
    {
      'id': '1',
      'username': 'moviebuff99',
      'email': 'moviebuff99@example.com',
      'role': 'User',
      'status': 'Active',
      'reports': 0,
      'join_date': '2023-01-15',
      'avatar': 'https://i.pravatar.cc/150?u=1',
    },
    {
      'id': '2',
      'username': 'cinephile_x',
      'email': 'cinephile_x@example.com',
      'role': 'Creator',
      'status': 'Active',
      'reports': 2,
      'join_date': '2023-02-20',
      'avatar': 'https://i.pravatar.cc/150?u=2',
    },
    {
      'id': '3',
      'username': 'troll_master',
      'email': 'troll@example.com',
      'role': 'User',
      'status': 'Banned',
      'reports': 15,
      'join_date': '2023-03-10',
      'avatar': 'https://i.pravatar.cc/150?u=3',
    },
     {
      'id': '4',
      'username': 'admin_jane',
      'email': 'jane@finishd.com',
      'role': 'Admin',
      'status': 'Active',
      'reports': 0,
      'join_date': '2022-11-01',
      'avatar': 'https://i.pravatar.cc/150?u=4',
    },
    {
      'id': '5',
      'username': 'newbie_dev',
      'email': 'dev@example.com',
      'role': 'User',
      'status': 'Shadowbanned',
      'reports': 5,
      'join_date': '2023-05-22',
      'avatar': 'https://i.pravatar.cc/150?u=5',
    },
  ];

  static const List<Map<String, dynamic>> creators = [
    {
      'id': '101',
      'username': 'film_critic_joe',
      'followers': 15400,
      'videos': 45,
      'engagement': '8.5%',
      'status': 'Approved',
      'avatar': 'https://i.pravatar.cc/150?u=101',
    },
    {
      'id': '102',
      'username': 'sarah_reviews',
      'followers': 8900,
      'videos': 22,
      'engagement': '12.1%',
      'status': 'Pending',
      'avatar': 'https://i.pravatar.cc/150?u=102',
    },
    {
      'id': '103',
      'username': 'action_fanatic',
      'followers': 2300,
      'videos': 10,
      'engagement': '5.4%',
      'status': 'Rejected',
      'avatar': 'https://i.pravatar.cc/150?u=103',
    },
  ];

  static const List<Map<String, dynamic>> reports = [
    {
      'id': 'r1',
      'type': 'Comment',
      'reason': 'Hate Speech',
      'reporter': 'user123',
      'reported_user': 'troll_master',
      'content': 'This movie is trash and so are you!',
      'severity': 'High',
      'status': 'Pending',
      'date': '2023-10-25 14:30',
    },
    {
      'id': 'r2',
      'type': 'Video',
      'reason': 'Copyright',
      'reporter': 'studio_admin',
      'reported_user': 'pirate_king',
      'content': '[Video Preview]',
      'severity': 'Medium',
      'status': 'Resolved',
      'date': '2023-10-24 09:15',
    },
    {
      'id': 'r3',
      'type': 'Post',
      'reason': 'Spam',
      'reporter': 'bot_hunter',
      'reported_user': 'spammer_01',
      'content': 'Click here for free movies!!!',
      'severity': 'Low',
      'status': 'Pending',
      'date': '2023-10-26 11:00',
    },
  ];

  static const List<Map<String, dynamic>> communities = [
    {
      'id': 'c1',
      'name': 'Inception Fans',
      'members': 12500,
      'toxicity': 12, // low
      'status': 'Active',
      'posts_per_day': 150,
    },
    {
      'id': 'c2',
      'name': 'SnyderCut Cult',
      'members': 8900,
      'toxicity': 78, // high
      'status': 'Flagged',
      'posts_per_day': 300,
    },
    {
      'id': 'c3',
      'name': 'Indie Gems',
      'members': 4500,
      'toxicity': 5,
      'status': 'Active',
      'posts_per_day': 45,
    },
  ];
}
