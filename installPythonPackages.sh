read -p "Enter the location you want to implement venv: " venv
read -p "Enter the name of the venv: " venvName
python3 -m venv ${venv}/${venvName}
cd ${venv}/${venvName}
source bin/activate

pip install Django uwsgi
sudo apt install nginx
sudo /etc/init.d/nginx start
read -p "Enter the name of the nginx conf file(eg: xxx.conf): " nginxCofig
cp nginxConfigTemplate.conf /etc/nginx/sites-available/${nginxCofig}

read -p "Enter directory of the Django project's media files: " dirDjango

echo "upstream django {" >> ${nginxCofig}

read -p "Enter the name of your Django project: " nameDjangoProject
echo "	server unix:///${dirDjango}/${nameDjangoProject}.sock;" >> ${nginxCofig}
echo "}" >> ${nginxCofig}
echo -e "\n" > ${nginxCofig}
echo "server {" >> ${nginxCofig}
echo "	listen 80;" >> ${nginxCofig}

read -p "Enter the website: " website
echo "	server_name ${website};" >> ${nginxCofig}
echo "	charset utf-8;" >> ${nginxCofig}
echo "	client_max_body_size 75M;" >> ${nginxCofig}
echo -e "\n" >> ${nginxCofig}
echo "	location /media {" ${nginxCofig}
echo "		alias ${dirDjango}/media;" ${nginxCofig}
echo "	}" >> ${nginxCofig}
echo -e "\n" >> ${nginxCofig}
echo "	location /static {" >> ${nginxCofig}
echo "		alias ${dirDjango}/static;" >> ${nginxCofig}
echo "	}" >> ${nginxCofig}
echo -e "\n" >> ${nginxCofig}
echo "	location / {" >> ${nginxCofig}
echo "		uwsgi_pass django;" >> ${nginxCofig}
echo "		include uwsgi_params;" >> ${nginxCofig}
echo "	}" >> ${nginxCofig}
echo "}" >> ${nginxCofig}


sudo ln -s /etc/nginx/sites-available/${nginxCofig} /etc/nginx/sites-enabled/

STATIC_ROOT = os.path.join(BASE_DIR, "static/")
python manage.py collectstatic

sudo /etc/init.d/nginx stop
sudo /etc/init.d/nginx start

read -p "Enter the filename of your uwsgi init(eg: xxx.ini): " uwsgiFileName
read -p "Enter the path to your project: " chdir
touch ${chdir}/${uwsgiFileName}
echo "[uwsgi]" >> ${uwsgiFileName}
echo "chdir = ${chdir}" >> ${uwsgiFileName}

echo "module = ${nameDjangoProject}/wsgi.py" >> ${uwsgiFileName}
echo "home = ${venv}/${venvName}" >> ${uwsgiFileName}
echo "master = true" >> ${uwsgiFileName}
echo "processes = 10" >> ${uwsgiFileName}
echo "socket = " >> ${uwsgiFileName}
ehco "vacuum = true" >> ${uwsgiFileName}

uwsgi --ini ${uwsgiFileName}

deactivate
sudo pip install uwsgi
uwsgi --ini ${uwsgiFileName}

sudo mkdir -p /etc/uwsgi/vassals
sudo ln -s /${chdir}/${uwsgiFileName} /etc/uwsgi/vassals/
sudo uwsgi --emperor /etc/uwsgi/vassals --uid www-data --gid www-data