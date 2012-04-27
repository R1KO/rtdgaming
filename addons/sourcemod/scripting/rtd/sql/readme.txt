http://www.rtdgaming.com/index.php?topic=224.msg16457#msg16457

1) Download Wamp (http://www.wampserver.com/en/download.php). This is used so that RTD can access a local database rather than going through the internet.

2) Launch Wamp and open http://localhost/phpmyadmin/

3) Import the attached file  localhost.sql with the default settings

Select GO

You will now have a database named: rtd_gamedb


4) Lastly, we need to tell Sourcemod the location of RTD's database. Browse to C:\TF2_Server\orangebox\tf\addons\sourcemod\configs and open up databases.cfg and add the following:

"rtdbank"
{
	"driver"		"mysql"
	"host"			"localhost" // The host where your mysql server is located
	"database"		"rtd_gamedb" // The name of the database
	"user"			"root"
	"pass"			""
	"port"			"3306"
}
