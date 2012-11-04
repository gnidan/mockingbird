MOCHA = @./node_modules/.bin/mocha \
	--compilers coffee:coffee-script

OPTS?=
FILES?=`find ./test -type f -name '*.coffee'`
export NODE_PATH=./app

xunit:
	$(MOCHA) -R xunit $(OPTS) $(FILES)

test:
	$(MOCHA) -R spec $(OPTS) $(FILES)

#test:
#	$(MOCHA) --ignore-leaks -R spec $(FILES)

debug:
	$(MOCHA) --debug-brk -R spec $(OPTS) $(FILES)

watch:
	$(MOCHA) -R dot -w $(OPTS) $(FILES)

update:
	@npm install

.PHONY: test
