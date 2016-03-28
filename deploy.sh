if [ -z "$1" ]; then
    echo "ERROR: version is required"    
    exit 1
fi 

VERSION=$1
NAME="pt_web.v"$VERSION".zip" 

strip pt_web
zip -r $NAME pt_web
aws s3 cp pt_web "s3://pt-spb/"$NAME
