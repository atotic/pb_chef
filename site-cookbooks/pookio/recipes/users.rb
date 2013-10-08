# The pookio user will run the app servers:
group 'pookio' do
  gid '2001'
end

user 'pookio' do
  home '/home/pookio'
  shell '/bin/bash'
  supports manage_home: true
  uid '2001'
  gid 'pookio'
end

# Make sure pookio can read the file at $SSH_AUTH_SOCK
# so it can `git clone` etc.:
group "append_to_deploy" do
  group_name "deploy"
  action :modify
  members ['pookio']
  append true
end

