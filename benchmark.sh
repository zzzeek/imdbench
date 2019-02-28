#!/bin/sh
SELFNAME=$0

usage()
{
    echo "Usage: $SELFNAME [options] [backends]"
    echo "  backends            - One or more of 'fsql', 'djrest',"
    echo "                        'djcustom'; if omitted all backends"
    echo "                        will be targeted"
    echo "Options:"
    echo "  -d, --duration <d>  - Specify how long each test will run,"
    echo "                        the argument may include units"
    echo "  -q, --query         - Gather additional timing data for"
    echo "                        SQL queries"
    echo "  -h, --help          - Print usage information"
}

if [ $# -eq 0 ]; then
    usage
    exit
fi

DUR=
QUERY=
BACKENDS=

while [ "$1" != "" ]; do
    case $1 in
        -d | --duration )       DUR=$2
                                shift
                                ;;
        -q | --query )          QUERY="_debug"
                                ;;
        -h | --help )           usage
                                exit
                                ;;
        * )                     BACKENDS="$BACKENDS $1"
                                ;;
    esac
    shift
done

if [ -z "$DUR" ]; then
    usage
    exit
fi

if [ -z "$BACKENDS" ]; then
    BACKENDS="fsql djrest djcustom"
fi

get_url()
{
    # $1 is the implementation type
    # $2 is pages
    # $3 is entity
    # $4 is tail
    case $1 in
        fsql)   URL="http://localhost:5000/$2$3_details/$4"
                ;;
        djrest)   URL="http://localhost:8010/webapp/api/$2$3_details/$4"
                ;;
        djcustom)   URL="http://localhost:8011/webapp/api/$2$3_details/$4"
                ;;
    esac
}

generic_bench()
{
    # $1 is the duration
    # $2 is the lua script
    # $3 is the test URL
    # $4 is the test arg (person, movie, user)
    wrk -t1 -c1 -d"$1" -s "$2" "$3" -- "$4"
}

for SRV in $BACKENDS
do
    echo "Testing $SRV$QUERY"
    for BTYPE in 'single' 'pages'
    do
        for ENTITY in 'movie' 'user' 'person'
        do
            if [ "$BTYPE" = "pages" ]; then
                PAGES="$BTYPE/"
                TAIL='?format=json&offset=%s'
            else
                PAGES=
                TAIL='%s?format=json'
            fi
            LUA="benchmarks/${BTYPE}${QUERY}.lua"

            echo $LUA $DUR

            get_url "$SRV" "$PAGES" "$ENTITY" "$TAIL"

            generic_bench "$DUR" "$LUA" "$URL" "$ENTITY"
        done
    done
    echo
    echo
done
