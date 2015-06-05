<?php
$adminuser = empty($_SERVER['OC_ADMIN_USER']) ? "admin" : $_SERVER['OC_ADMIN_USER'];
$adminpass = empty($_SERVER['OC_ADMIN_PASS']) ? "Password" : $_SERVER['OC_ADMIN_PASS'];
$dbuser = "root";
$dbpass = $_SERVER['DB_REMOTE_ROOT_PASS'];
$config = <<<EOD
<?php
\$AUTOCONFIG = array(
  "directory"     => "/opt/owncloud/data",
  "adminlogin"    => "$adminuser",
  'adminpass'     => "$adminpass",
  "dbtype"        => "mysql",
  "dbname"        => "owncloud",
  "dbuser"        => "$dbuser",
  "dbpass"        => "$dbpass",
  "dbhost"        => "localhost",
  "dbtableprefix" => "",
);
EOD;
print $config;
?>
