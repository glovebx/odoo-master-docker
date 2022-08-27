# odoo-master-docker
create dockerfile from source for odoo master branch on Mac M1

1、Install Docker
2、create project folder like below
   odoo16--|
           odoo
         --|
           Dockerfile
         --|
           entrypoint.sh
         --|
           odoo.conf
         --|
           wait-for-psql.py
3、clone odoo master branch into [odoo] folder
4、open folder [odoo16] with Visual Studio Code, must install docker extension first
5、Build odoo image with docker name [odoo16]
6、Pull postgres image and run
   docker run -d -p 5432:5432 -e POSTGRES_USER=odoo -e POSTGRES_PASSWORD=odoo -e POSTGRES_DB=postgres --name db postgres:13
7、Run odoo image
   docker run -p 8069:8069 --name odoo16 --link db:db -t odoo16
8、open http://localhost:8069 with browser
