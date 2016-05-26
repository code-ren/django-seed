#!/usr/bin/env bash

# https://github.com/Divi/VagrantBootstrap


# ------------------------------------------------
# Project Name, set in Vagrantfile
# ------------------------------------------------
projectName=$1
djangoName=$2


# ------------------------------------------------
# Update the box release repositories
# ------------------------------------------------
echo '***************************** Apt Update *****************************'
export DEBIAN_FRONTEND=noninteractive
#sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" >> /etc/apt/sources.list.d/pgdg.list'
#wget -q https://www.postgresql.org/media/keys/ACCC4CF8.asc -O - | apt-key add -
apt-get update


echo '***************************** System settings *****************************'

# Terminal
echo "PS1='$projectName(\u):\w# ' " >> /root/.bashrc
echo "PS1='$projectName(\u):\w\$ ' " >> /home/vagrant/.bashrc

# ------------------------------------------------
# PostgreSQL 
# ------------------------------------------------
echo '***************************** Installing and configuring PostgreSQL *****************************'
apt-get -y install postgresql postgresql-contrib postgresql-client-common libpq-dev

echo "
CREATE DATABASE $projectName;
CREATE USER djangouser WITH PASSWORD 'tarantula';
ALTER ROLE djangouser SET client_encoding TO 'utf8';
ALTER ROLE djangouser SET default_transaction_isolation TO 'read committed';
ALTER ROLE djangouser SET timezone TO 'UTC';
GRANT ALL PRIVILEGES ON DATABASE $projectName TO djangouser;
" | sudo -u postgres psql


# ------------------------------------------------
# Python 
# ------------------------------------------------
echo '***************************** Installing and configuring Python *****************************'
apt-get install -y python python-pip python-psycopg2

# ------------------------------------------------
# Django 
# ------------------------------------------------
echo '***************************** Installing and configuring Django *****************************'
pip install Django==1.9.6
pip install psycopg2
cd /home/project/$projectName; django-admin.py startproject $djangoName .

echo "
import os

# Build paths inside the project like this: os.path.join(BASE_DIR, ...)
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


# Quick-start development settings - unsuitable for production
# See https://docs.djangoproject.com/en/1.9/howto/deployment/checklist/

# SECURITY WARNING: keep the secret key used in production secret!
SECRET_KEY = '@b%g*kc-l!hoccg4dyj6l_c4%a3sh%bx96d^1ak!(lmakaq84('

# SECURITY WARNING: don't run with debug turned on in production!
DEBUG = True

ALLOWED_HOSTS = []


# Application definition

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
]

MIDDLEWARE_CLASSES = [
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.auth.middleware.SessionAuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'unchained.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'unchained.wsgi.application'


# Database
# https://docs.djangoproject.com/en/1.9/ref/settings/#databases

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql_psycopg2',
        'NAME': '$projectName',
        'USER': 'djangouser',
        'PASSWORD': 'tarantula',
        'HOST': 'localhost',
        'PORT': '',
    }
}


# Password validation
# https://docs.djangoproject.com/en/1.9/ref/settings/#auth-password-validators

AUTH_PASSWORD_VALIDATORS = [
    {
        'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator',
    },
]


# Internationalization
# https://docs.djangoproject.com/en/1.9/topics/i18n/

LANGUAGE_CODE = 'en-us'

TIME_ZONE = 'UTC'

USE_I18N = True

USE_L10N = True

USE_TZ = True


# Static files (CSS, JavaScript, Images)
# https://docs.djangoproject.com/en/1.9/howto/static-files/

STATIC_URL = '/static/'
" > /home/project/$projectName/$djangoName/settings.py

python manage.py makemigrations
python manage.py migrate

echo '***************************** Installing Postfix  *****************************'
debconf-set-selections <<< "postfix postfix/mailname string localhost"
debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"
apt-get install -y postfix

# ------------------------------------------------
# Finish up
# ------------------------------------------------
# set permission for vagrant user
chown -R vagrant /home/project

echo '***************************** Completed bootstrap.sh for $projectName *****************************'
echo '
** Helpful Vagrant commands **
vagrant up
vagrant suspend
vagrant halt
vagrant ssh
vagrant global-status --prune && vagrant global-status
python manage.py makemigrations
python manage.py migrate

***************************** To Start Django *****************************
vagrant ssh
cd /home/project/python27
python manage.py createsuperuser
python manage.py runserver 0.0.0.0:8000
Open a browser to localhost:9999 and localhost:9999/admin
'
