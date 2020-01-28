#default.rb

execute "sudo apt-get update"
['apache2', 'php', 'php-mbstring', 'php-zip', 'phpunit', 'unzip', 'libapache2-mod-php'].each do |p|
  package p do
    action :install
  end
end
execute "sudo echo 'mysql-server mysql-server/root_password password admin' | debconf-set-selections"
execute  "sudo echo 'mysql-server mysql-server/root_password_again password admin' | debconf-set-selections"

package 'mysql-server'
service 'mysql' do
  supports :status => true, :restart => true, :reload => true
  action [:enable, :start]
end

execute "mysql -u root -padmin < /vagrant/createUser.sql"
execute "installComposer" do
  command "curl -Ss https://getcomposer.org/installer | php"
  user "vagrant"
  cwd "/tmp"
  environment 'HOME'  => '/home/vagrant'
end
execute "sudo mv /tmp/composer.phar /usr/bin/composer"
execute "installLaravel" do
  command "composer global require laravel/installer"
  user "vagrant"
  environment 'HOME'  => '/home/vagrant'
end
execute "sudo chown -R vagrant:vagrant /var/www"
execute "createProject" do
  command "composer create-project --prefer-dist laravel/laravel myProject"
  user "vagrant"
  cwd "/var/www"
  environment 'HOME'  => '/home/vagrant'
end
execute "chmod -R 777 /var/www/myProject/storage"
execute "sudo sed -i 's/DocumentRoot.*/DocumentRoot \\/var\\/www\\/myProject\\/public/' /etc/apache2/sites-available/000-default.conf"
execute "sed -i '/mysql/{n;n;n;n;s/'\\''DB_DATABASE'\\'', '\\''.*'\\''/'\\''DB_DATABASE'\\'', '\\''myproject'\\''/g}' /var/www/myProject/config/database.php"
execute "sed -i '/mysql/{n;n;n;n;n;s/'\\''DB_USERNAME'\\'', '\\''.*'\\''/'\\''DB_USERNAME'\\'', '\\''myproject'\\''/g}' /var/www/myProject/config/database.php"
execute "sed -i '/mysql/{n;n;n;n;n;n;s/'\\''DB_PASSWORD'\\'', '\\''.*'\\''/'\\''DB_PASSWORD'\\'', '\\''mypassword'\\''/g}' /var/www/myProject/config/database.php"
service 'apache2' do
  supports :status => true, :restart => true, :reload => true
  action [ :enable, :restart]
end



