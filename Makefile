
PROFTEST=

CCC= ruby

CCFLAGS= 

clean:
	rm -f *.j
	rm -f *.out
	rm -f *.class
	ls

compiler: 
	echo "Ruby is interpreted, does not compile"

stutest.out: compiler
	cat stutest.in
	$(CCC) driver.rb stutest.in
	java -jar jasmin.jar stutest.j
	java stutest > stutest.out
	cat stutest.out
