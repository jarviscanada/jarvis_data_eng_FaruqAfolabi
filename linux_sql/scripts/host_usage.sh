psql_host=$1
psql_port=$2
db_name=$3
psql_user=$4
psql_password=$5

if [ "$#" -ne 5 ]; then
  echo "Illegal number of parameters"
  exit 1
fi

vmstat_mb=$(vmstat --unit M)
hostname=$(hostname -f | xargs)

memory_free=$(echo "$vmstat_mb" | awk '{print $4}' | tail -n 1 | xargs)
cpu_idle=$(echo "$vmstat_mb" | awk '{print $15}' | tail -n 1 | xargs)
cpu_kernel=$(echo "$vmstat_mb" | awk '{print $14}' | tail -n 1 | xargs)
disk_io=$(vmstat --unit M -d | awk '{print $10}' | tail -n 1 | xargs)
disk_available=$(df -BM | egrep "/$" | awk -F '[^0-9]+' '{print $4}' | tail -n 1 | xargs)

timestamp=`date "+%Y-%m-%d %T"`

export PGPASSWORD=$psql_password
get_host_id="SELECT id FROM host_info WHERE hostname='$hostname';";
host_id=$(psql -h "$psql_host" -p "$psql_port" -d "$db_name" -U "$psql_user" -t -c "$get_host_id")

insert_stmt="INSERT INTO host_usage(timestamp, host_id, memory_free, cpu_idle, cpu_kernel, disk_io, disk_available)
VALUES('$timestamp', '$host_id', '$memory_free', '$cpu_idle', '$cpu_kernel', '$disk_io', '$disk_available')";

export PGPASSWORD=$psql_password

psql -h "$psql_host" -p "$psql_port" -d "$db_name" -U "$psql_user" -c "$insert_stmt"
exit $?