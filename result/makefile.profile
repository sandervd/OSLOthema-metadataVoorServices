SHELL=/bin/bash
VALIDATORAPI=https://data.vlaanderen.be/shacl-validator-backend/shacl/applicatieprofielen/api/validate 
PROFILE=ENVPROFILE
VALPATH=$(shell pwd | sed "s/.*\(testdata.*\)/\1/" )



# Process the rulefiles
TESTDATAFILES=${wildcard *.nt}
TESTDATARES=$(patsubst %.nt,%.result,${TESTDATAFILES})
TESTDATARESCSV=$(patsubst %.nt,%.csv,${TESTDATAFILES})

all: ${TESTDATARESCSV}

.PRECIOUS: %.result
%.result: %.nt
	curl -H "Content-type:application/json" \
	     -H "Accept: application/json" \
	     -d '{"contentToValidate":"https://github.com/Informatievlaanderen/OSLOthema-metadataVoorServices/raw/validation/${VALPATH}/$<","validationType":"${PROFILE}", "reportSyntax":"application/ld+json"}' \
	     ${VALIDATORAPI} > $@

.PRECIOUS: %.csv
%.csv: %.result
	jq '."@graph"[] | [."sourceShape",."@id"] | join(";")' $< | sed 's/\"//g' | sort -t ";" -k 1 >> $@
	sed -i "s/\r//g" $@
	sed -i "1d" $@
	sed -i "s/;.*$$/;x/" $@
	sort -u $@ > /tmp/$@
	cp /tmp/$@ $@
	sed -i "1i rule;${VALPATH}/$<" $@


clean:
	rm -rf ${TESTDATARES} ${TESTDATARESCSV}


