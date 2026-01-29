#!/bin/bash
# SYSTEM HEALTH CHECKER
# Krāsas izvadei
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;36m'  # Tirkīzs
CYAN='\033[1;36m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Mainīgie
SCRIPT_NAME="System Health Checker"
VERSION="1.0"
AUTHOR="Aivars Klavins"
CHECK_TIME=$(date "+%Y-%m-%d %H:%M:%S")

TIPS=(
    "Regulāri tīriet nevajadzīgos failus no /tmp mapes"
    "Pārbaudiet sistēmas žurnālus: sudo journalctl -xe"
    "Atjauniniet sistēmu: sudo apt update && sudo apt upgrade"
    "Veiciet regulāras rezerves kopiju izveidi"
    "Pārbaudiet, vai ugunsmūra noteikumi ir pareizi"
)

# Funkcija krāsainai izvadei
print_color() {
    echo -e "${2}${1}${NC}"
}

# Funkcija progresa joslai
show_progress() {
    local duration=$1
    local steps=20
    for ((i=0; i<=steps; i++)); do
        printf "\r["
        for ((j=0; j<i; j++)); do
            printf "-"
        done
        for ((j=i; j<steps; j++)); do
            printf "."
        done
        printf "] %d%%" $((i*100/steps))
        sleep 0.02
    done
    printf "\n"
}

clear
print_color "      $SCRIPT_NAME v$VERSION     " $PURPLE
print_color "---------------------------" $CYAN
echo ""
print_color "Sveicināti, $AUTHOR!" $GREEN
print_color "Pārbaudes laiks: $CHECK_TIME" $BLUE
echo ""

# Sākam pārbaudi
print_color "Sāku sistēmas pārbaudi..." $CYAN
show_progress 0.5

#  1. DISKA VIETA 
echo ""
print_color "DISKA LIETOJUMS:" $BLUE
echo "--------------------------------"

DISK_INFO=$(df -h / | tail -1)
DISK_USED=$(echo $DISK_INFO | awk '{print $5}' | tr -d '%')
DISK_TOTAL=$(echo $DISK_INFO | awk '{print $2}')
DISK_FREE=$(echo $DISK_INFO | awk '{print $4}')

print_color "Kopējā vieta: $DISK_TOTAL" $NC
print_color "Brīvā vieta: $DISK_FREE" $NC

if [ $DISK_USED -lt 70 ]; then
    print_color "Statuss: ✅ Labi ($DISK_USED% izmantots)" $GREEN
elif [ $DISK_USED -lt 90 ]; then
    print_color "Statuss: ⚠️  Brīdinājums ($DISK_USED% izmantots)" $YELLOW
else
    print_color "Statuss: ❌ KRĪTISKI ($DISK_USED% izmantots)" $RED
fi

# 2. ATMIŅA (RAM)
echo ""
print_color "OPERATĪVĀ ATMIŅA:" $BLUE
echo "--------------------------------"

if command -v free &> /dev/null; then
    MEM_INFO=$(free -m | grep Mem)
    MEM_TOTAL=$(echo $MEM_INFO | awk '{print $2}')
    MEM_USED=$(echo $MEM_INFO | awk '{print $3}')
    MEM_PERCENT=$((MEM_USED * 100 / MEM_TOTAL))
    
    print_color "Kopā: ${MEM_TOTAL}MB" $NC
    print_color "Izmantota: ${MEM_USED}MB (${MEM_PERCENT}%)" $NC
    
    if [ $MEM_PERCENT -lt 70 ]; then
        print_color "Statuss: ✅ Labi" $GREEN
    elif [ $MEM_PERCENT -lt 85 ]; then
        print_color "Statuss: ⚠️  Normāli" $YELLOW
    else
        print_color "Statuss: ❌ Augsta slodze" $RED
    fi
else
    print_color "Komanda 'free' nav pieejama" $YELLOW
fi

# 3. CPU SLODZE 
echo ""
print_color "CPU SLODZE:" $BLUE
echo "--------------------------------"

if command -v uptime &> /dev/null; then
    LOAD=$(uptime | awk -F'load average:' '{print $2}')
    print_color "Slodze (1, 5, 15 min): $LOAD" $NC
    
    CPU_COUNT=$(nproc 2>/dev/null || echo 1)
    LOAD1=$(echo $LOAD | awk -F', ' '{print $1}' | tr -d ',')
    
    if (( $(echo "$LOAD1 < $CPU_COUNT" | bc -l 2>/dev/null || echo "1") )); then
        print_color "Statuss: ✅ Normāla slodze" $GREEN
    else
        print_color "Statuss: ⚠️  Augsta slodze" $YELLOW
    fi
fi

# 4. SISTĒMAS INFORMĀCIJA 
echo ""
print_color "SISTĒMAS DETALAS:" $BLUE
echo "--------------------------------"

print_color "OS: $(uname -s) $(uname -r)" $NC
print_color "Hostname: $(hostname)" $NC

UPTIME_CMD=$(uptime -p 2>/dev/null || echo "N/A")
print_color "Uptime: $UPTIME_CMD" $NC

print_color "Laiks: $(date)" $NC
print_color "Lietotājs: $USER" $NC

# 5. KOPĒJAIS NOVĒRTĒJUMS 
echo ""
print_color "KOPĒJAIS NOVĒRTĒJUMS:" $YELLOW
echo "--------------------------------"

SCORE=0
TOTAL_TESTS=3

[ $DISK_USED -lt 85 ] && ((SCORE++))
[ ${MEM_PERCENT:-0} -lt 80 ] && ((SCORE++))

if [ $SCORE -eq $TOTAL_TESTS ]; then
    print_color "✅ VISS LABI! ($SCORE/$TOTAL_TESTS)" $GREEN
    print_color "Sistēma vesela un spējīga!" $GREEN
elif [ $SCORE -ge 2 ]; then
    print_color "⚠️  VIDĒJI ($SCORE/$TOTAL_TESTS)" $YELLOW
    print_color "Daži uzlabojumi nepieciešami!" $YELLOW
else
    print_color "❌ SLIKTI ($SCORE/$TOTAL_TESTS)" $RED
    print_color "Nepieciešama uzmanība!" $RED
fi

# 6. PADOMI (atkarībā no rezultāta)
if [ $SCORE -lt $TOTAL_TESTS ]; then
    echo ""
    print_color "PADOMS:" $PURPLE
    echo "--------------------------------"
    
    # Dažādi padomi atkarībā no rezultāta
    if [ $SCORE -eq 2 ]; then
        # Vidēji rezultātam
        PADOMI=(
            "Pārbaudiet, vai nav nevajadzīgu failu diska"
            "Apsveriet iespēju palielināt SWAP atmiņu"
            "Pārbaudiet, vai nav nevajadzīgu procesu"
        )
    else
        # Sliktam rezultātam
        PADOMI=(
            "URGENT: Disks vai atmiņa ir kritiski!"
            "Nepieciešams nekavējoties atbrīvot vietu"
            "Apsveriet aparatūras jaudības palielināšanu"
        )
    fi
    
    RANDOM_INDEX=$((RANDOM % ${#PADOMI[@]}))
    print_color "${PADOMI[$RANDOM_INDEX]}" $CYAN
fi

# 7. APKOPOJUMS 
echo ""
print_color "-----------------------------------------" $CYAN
print_color "🏁 PĀRBAUDE PABEIGTA!" $GREEN
print_color "Izmantojiet šo skriptu regulāri," $YELLOW
print_color "lai sekotu līdzi savas sistēmas veselībai!" $YELLOW
echo ""
print_color "Paldies par lietošanu!" $PURPLE