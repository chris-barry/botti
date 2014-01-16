#!/bin/sh

##
# A suckless irc bot
# License: Unlicense. See LICENSE.md.
##
# TODO: fork less
##

leave() {
	if [ -f out ]; then
		echo "Leaving channel"
		echo "Goodbye!" > in
		echo "/l" > in
	fi
	echo "Cleaning up"
	cd ../..
	kill $PID
	rm -rf $HOST
	exit
}

if [ ! -f botii.conf ]; then
	echo "You need to make your config file!"
	echo "See botii.conf"
fi;

# Load configuration
. $PWD/botii.conf

trap leave SIGINT

# Remove the host just incase we didn't clean up
rm -rf $HOST

# Start ii and save the pid
$II -i $II_DIR -s $HOST -p $PORT -n $NICK -k $PASS -f $FULL_NAME &
PID=$!

echo "Connecting to" $HOST
while [ ! -d $HOST ]; do
	echo "Waiting for" $HOST
	sleep 1
done
cd $HOST

while [ ! -f out ]; do
	sleep 1
done

echo "Checking if username is taken"
while [ "$(tail -n2 out | awk '{print $6}')" = "already" ]; do
	echo "Nickname already in use."
	NICK=$NICK"_"
	echo "/n" $NICK > in
	sleep 1
done

echo "Joining" $CHANNEL
echo "/j" $CHANNEL > in
while [ ! -d $CHANNEL ]; do
	echo "Waiting for" $CHANNEL
	sleep 1
done
cd $CHANNEL
echo "Connected."

while [ ! -f out ]; do
	echo "Waiting on output file..."
	sleep 1
done

# TODO There's probably a better way to read `out`
echo "Bot started."
while : ; do
	CURRENT=$(tail -n1 out)
	if [ "$LAST" = "$CURRENT" ]; then
		sleep 1
		continue
	fi;
	LAST=$CURRENT

	# XXX make some cool responses to server messages
	if [ "$(echo $CURRENT | awk '{print $3}')" = "-!-" ]; then
		echo "Server message"
		sleep 1
		continue
	fi

	# User said something
	DATE="$(echo $CURRENT | awk '{print $1}')"
	TIME="$(echo $CURRENT | awk '{print $2}')"
	USERNAME="$(echo $CURRENT | awk '{print $3}' | tr -d '<' | tr -d '>')"

	# Command is the first word the user said
	COMMAND="$(echo $CURRENT | awk '{print $4}')"

	# Message is every word following what the user said
	MESSAGE="$(echo $CURRENT | awk '{for(i=5;i<=NF;++i) printf("%s ", $i)}')"

	# XXX make some cool commands
	case $COMMAND in
	".hi")
		echo "Hello" $USERNAME", how are you?" > in
		;;
	".date")
		date -u > in
		;;
	".uptime")
		uptime > in
		;;
	".echo")
		echo $COMMAND $MESSAGE > in
	".about")
		echo "I am a bot." > in
		;;
	".die")
		leave
		;;
	".isup")
		SITE="$(echo $CURRENT | awk '{print $5}')"
		if [ -z "$SITE" ]; then
			echo "No site supplied." > in
		elif [ ! -z "$(curl -sL --head --request GET $SITE | grep '200 OK')" ]; then
			echo $SITE "is up" > in
		else
			echo $SITE "is down" > in
		fi
		;;
	".whatFoxSay")
		echo "DING DING DING DING" > in
		echo "WOP WOP WOP WOP WOP" > in
		echo "POW POW POW POW POW POW" > in
		echo "What the fox say?" > in
		;;
	esac
	sleep 1
done

exit
