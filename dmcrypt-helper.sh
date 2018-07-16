#!/bin/bash                                                                                                            
# -x   

FILENAME="/tmp/crypt";                                                                                          
FILESIZE="10M";                                                                                                       
VOLUMENAME="crypt"                                                                                                   

DMH_create() {                                                                                                         
                                                                                                                       
    if [ ! -f $FILENAME ]; then                                                                                          
        set -x                                                                                                           
        echo "Creating image file...";                                                                                   
        #    dd if=/dev/zero of=$FILENAME bs=$FILESIZE count=0 seek=1
        fallocate -l $FILESIZE $FILENAME

        echo "Setting permissions...";
        chmod 600 $FILENAME;

        ##############################################################
        echo "Create container"
        #cryptsetup --hash sha512 --key-size 512 --iter-time 5000 luksFormat /dev/loop0 encrypted;
        cryptsetup -y luksFormat --hash sha512 --key-size 512 --use-random --iter-time 5000 $FILENAME

        ##############################################################
        echo "Container checks" 
        ls -lah $FILENAME
        file $FILENAME

        ##############################################################
        echo "Create filesystem" 
        cryptsetup luksOpen $FILENAME $VOLUMENAME
        mkfs.ext4 -j /dev/mapper/$VOLUMENAME

        ##############################################################
        echo "First mount" 
        mkdir -p /mnt/encrypted
        mount /dev/mapper/$VOLUMENAME /mnt/encrypted
        df -h 
        ls -lah /mnt/encrypted/
        echo "test"  > /mnt/encrypted/test 
        set +x 
    fi

}

DMH_mount() {

    set -x   
    cryptsetup luksOpen $FILENAME $VOLUMENAME 
    mount /dev/mapper/$VOLUMENAME /mnt/encrypted
    df -h 
    ls -lah /mnt/encrypted
    set +x 
}

 

DMH_umount() {

    df -h | grep mapper 
    echo "umount $VOLUMENAME" 
    umount /dev/mapper/$VOLUMENAME
    cryptsetup luksClose $VOLUMENAME
    echo "check " 
    df -h
}

###############################################################################
###############################################################################

die()
{
    local _ret=$2
    test -n "$_ret" || _ret=1
    test "$_PRINT_HELP" = yes && print_help >&2
    echo "$1" >&2
    exit ${_ret}
}

begins_with_short_option()
{
    local first_option all_short_options
    all_short_options='th'
    first_option="${1:0:1}"
    test "$all_short_options" = "${all_short_options/$first_option/}" && return 1 || return 0
}

###############################################################################

print_help ()
{
    printf "%s\n" "dmcrypt helper :    "
    printf 'Usage: %s [option] or [-h|--help]\n' "$0"
    printf "\n" 
    printf "\t%s\n" "-c,--create : create a new container " 
    printf "\t%s\n" "-m,--mount  : mount the container " 
    printf "\t%s\n" "-u,--umount : umount the container" 
    printf "\t%s\n" "-h,--help: Prints this help"
    printf "\n" 
}

parse_commandline ()
{
    while test $# -gt 0
    do
        _key="$1"
        case "$_key" in
            -c|--create)
                    DMH_create
                    exit 0
                    ;;
            -m|--mount)
                    DMH_mount 
                    exit 0
                    ;;
            -u|--umount)
                    DMH_umount 
                    exit 0
                    ;;
            -h|--help)
                    print_help
                    exit 0
                    ;;
            *)
                    _PRINT_HELP=yes die "FATAL ERROR: Got an unexpected argument '$1'" 1
                    ;;
        esac
        shift
    done
}

parse_commandline "$@"
