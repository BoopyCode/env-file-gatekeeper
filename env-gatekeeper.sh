#!/bin/bash
# .env File Gatekeeper - Because developers are sneaky little hobbitses

# Colors for our dramatic warnings
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# The forbidden patterns - we know your tricks!
FORBIDDEN_PATTERNS=(".env*" "*.env" "env.*" "secrets.*" "config.*")

# Check if we're in a git repo (because why else would you run this?)
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}Not in a git repository. Are you lost?${NC}"
    exit 1
fi

# Look for sneaky files
FOUND_FILES=()
for pattern in "${FORBIDDEN_PATTERNS[@]}"; do
    while IFS= read -r -d '' file; do
        # Skip .gitignore because we're not monsters
        if [[ "$file" != *".gitignore" ]]; then
            FOUND_FILES+=("$file")
        fi
    done < <(find . -name "$pattern" -type f -print0 2>/dev/null)
done

# The moment of truth
if [ ${#FOUND_FILES[@]} -eq 0 ]; then
    echo -e "${GREEN}✓ No forbidden files found. You're a good developer!${NC}"
    exit 0
fi

# Oh dear...
echo -e "${RED}⚠  DANGER WILL ROBINSON! Found forbidden files:${NC}"
for file in "${FOUND_FILES[@]}"; do
    echo -e "${YELLOW}  • $file${NC}"
    
    # Check if it's in .gitignore (common rookie mistake)
    if grep -q "$(basename "$file")" .gitignore 2>/dev/null; then
        echo -e "    ${RED}But wait... it's in .gitignore! Classic misdirection.${NC}"
    fi
    
    # Check if it's already tracked (oh no)
    if git ls-files --error-unmatch "$file" > /dev/null 2>&1; then
        echo -e "    ${RED}AND IT'S ALREADY TRACKED! PANIC!${NC}"
    fi
done

echo -e "\n${RED}🚫 These files should NOT be committed. Add them to .gitignore!${NC}"
echo -e "${YELLOW}💡 Pro tip: Use .env.example for non-sensitive defaults${NC}"

exit 1