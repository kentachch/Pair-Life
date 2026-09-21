
if Rails.env.development?
  [
    { name: "ユーザー1", email: "user1@example.com" },
    { name: "ユーザー2", email: "user2@example.com" }
  ].each do |attrs|
    User.find_or_create_by!(email: attrs[:email]) do |user|
      user.name = attrs[:name]
      user.password = "password"
    end
  end
end
