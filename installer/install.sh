echo ""
echo "This is the Project Application Tool (PAT) install script."
echo " located at http://static.ministryapp.com/canada/pat_auto/install.sh"
echo ""
echo "Important: You should be root."
echo ""
echo -n "Continue? (y/n) "
read answer

if [ $answer == "y" ]
then

  # install required packages
  echo "First making sure ruby and subversion are installed.."
  echo ""
  apt-get install ruby irb subversion

  # check out everything locally
  echo "Checking out installer code"
  echo ""
  #svn co https://svn.ministryapp.com/pat/trunk/installer pat_installer

  # now switch to the ruby installer
  #ruby pat_installer/install.rb
  ruby installer/install.rb
fi

