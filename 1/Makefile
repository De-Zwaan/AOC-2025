# Rule to assemble the .asm file into an object file
%.o : %.asm input.txt test_input.txt
	nasm -f elf64 -o $@ $<

# Rule to link the object file into an executable
% : %.o
	ld -o $@ $<
