XML_IFC_EXP="//*[local-name()='interface']/address/@slot" 

# get_xml_attr_value $XML_IFC_EXP smartcity_cloud.xml
function get_xml_attr_value(){
ret=()
str=$(xmllint --xpath "$1" $2)
entries=($(echo ${str}))
for entry in "${entries[@]}"; do
  result=$(echo $entry | awk -F'[="]' '!/>/{print $(NF-1)}')
  ret+=("$result")
done
echo ${ret[@]}
}

function str2jsonlist(){
  echo "[\"${1/ /\", \"}\"]"
}

function get_xml_elem_text(){
  echo "Not implementation"
}

