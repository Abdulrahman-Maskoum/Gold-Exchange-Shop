class UserModel {
  final String uid;
  final String username;
  final String email;
  final String shopName;
  final String shopAddress;

  const UserModel({
    required this.uid,
    required this.username,
    required this.email,
    required this.shopName,
    required this.shopAddress,
  });

  factory UserModel.fromMap(String uid, Map<String, dynamic> data) {
    return UserModel(
      uid: uid,
      username: (data['username'] ?? '') as String,
      email: (data['email'] ?? '') as String,
      shopName: (data['shopName'] ?? '') as String,
      shopAddress: (data['shopAddress'] ?? '') as String,
    );
  }

}
