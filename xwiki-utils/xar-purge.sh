#!/bin/bash
#
## Configuration ##

dest_dir="/home/xwiki/XARs/"

excluded="Main.WebHome
Main.Welcome
XWiki.MessageStreamConfig
XWiki.RegistrationConfig
XWiki.WysiwygEditorConfig
XWiki.SearchSuggestConfig
AnnotationCode.AnnotationConfig
Invitation.InvitationConfig
XWiki.XWikiAllGroup
XWiki.XWikiAdminGroup
XWiki.Admin
XWiki.DefaultSkin
XWiki.XWikiSkins
Sandbox.WebHome
XWiki.XWikiPreferences
Main.Search
Main.WebSearch
XWiki.XWikiSyntax
Blog.BlogIntroduction
XWiki.ForgotUsername
Blog.Other
Blog.Personal
XWiki.ResetPassword
XWiki.AdminSheet
Scheduler.WebPreferences
Blog.News
AppWithinMinutes.ClassEditSheet
Panels.DocumentInformation
XWiki.LuceneSearchAdmin
XWiki.WatchListMessage
Panels.QuickLinks
Panels.Welcome"

######################

exec 2> $0.err

errcount=0

if [ ! -d $dest_dir ]
then
	echo "Directory $dest_dir doesn't exist! I'll try to create it."
	mkdir $dest_dir
	if [[ $? != "0" ]]
	then
		echo "$dest_dir cannot be created. Perhaps a lack of rights?"
		exit 1
	fi
fi

if [[ "`which unzip &>/dev/null; echo $?`" != "0"  || "`which zip &>/dev/null; echo $?`" != "0" ]]
then
	echo "Zip or/and Unzip utils have not been found on your system. Exiting..."
	exit 1
fi

### Type input
echo "Choose a type between XE and XEM [default:XE]"
read package_type

if [[ $package_type != "XE" && $package_type != "XEM" && $package_type != "" ]]
then
	echo "This version of XWiki is not recognized (type XE or XEM)"
	exit 1
fi

if [[ $package_type == "" ]] 
then
	package_type="XE"
fi

### Version input
echo "What version of XE are you using?"
read xar_version

if [[ "`echo ${xar_version:0:1} | egrep [3-5]`" == "" ]]
then
	echo "This version is not a real version. (type for example: 4.1.4)"
	exit 1
fi

### Downloading standard XAR
echo "Downloading XWiki $package_type for version $xar_version ..."
if [[ $package_type == "XE" || $package_type == "" ]]
then
	wget -O "XARs/$package_type-$xar_version.xar" http://maven.xwiki.org/releases/org/xwiki/enterprise/xwiki-enterprise-ui-all/$xar_version/xwiki-enterprise-ui-all-$xar_version.xar 1>/dev/null
else
	wget -O "XARs/$package_type-$xar_version.xar" http://maven.xwiki.org/releases/org/xwiki/manager/xwiki-manager-ui-all/$xar_version/xwiki-manager-ui-all-$xar_version.xar 1>/dev/null

	if [[ $? != '0' ]]
	then
		echo "Download have failed. Please check $0.err file for more details (Perhaps this version doesn't exist?)."
		exit 1
	fi
fi

### Unzip 

mkdir "$package_type-$xar_version.tmp" ; unzip XARs/$package_type-$xar_version.xar -d $package_type-$xar_version.tmp/ 1>/dev/null
cd "$package_type-$xar_version.tmp/"

### Deleting the flagged files

for doc in $excluded
do
	docpage="`echo $doc|cut -d'.' -f2`"
	docspace="`echo $doc|cut -d'.' -f1`"

	# Deleting xml file
	rm $docspace/$docpage.xml
	if [[ $? != "0" ]]
	then
		echo "ERROR during the deletion of $docpage in space $docspace (file not found)."
		errcount="`expr $errcount + 1`"
	fi
	
	# Deleting the occurence in package.xml
	sed "/$docspace.$docpage<\/file>/d" package.xml > package.xml.new
	if [[ $? == "0" ]]
	then
		mv package.xml.new package.xml
	else
		echo "The page $docpage from space $docspace haven't been found (file not in package.xml)."
	fi
done

## Packing the new .xar package
echo "Cleaning is over. Building the new xar..."

zip -r ../$package_type-$xar_version-purged.xar * 1>/dev/null
cd ../
mv $package_type-$xar_version-purged.xar $dest_dir
rm -rf $package_type-$xar_version.tmp

echo "Moving new xar package in $dest_dir/$package_type-$xar_version-purged.xar"
echo "Operation OK - $errcount files with error. Please check $0.err log file for more details about eventual issues."

