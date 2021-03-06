/******************************************************************************
 * (C) Copyright 2016 AMIQ Consulting
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 *******************************************************************************/

`ifndef __yamm_buffer_debug
`define __yamm_buffer_debug

function void yamm_buffer::print(bit recursive=0);
	int i;
	yamm_buffer handle_to_buffer;
	handle_to_buffer = first;
	i = 0;

	// Traverse the memory and print the hidden data inside each buffer
	while(handle_to_buffer)
	begin
		`ifdef YAMM_USE_UVM
		`uvm_info("YAMM_INF", $sformatf("%0d . Size: %d  Start_addr: %d  End addr: %d Free: %0d Static: %0d", i, handle_to_buffer.size, handle_to_buffer.start_addr, handle_to_buffer.end_addr, handle_to_buffer.is_free, handle_to_buffer.is_static), UVM_MEDIUM)
		`else
		$display("%0d . Size: %d  Start_addr: %d  End addr: %d Free: %0d Static: %0d", i, handle_to_buffer.size, handle_to_buffer.start_addr, handle_to_buffer.end_addr, handle_to_buffer.is_free, handle_to_buffer.is_static);
		`endif


		// If there are any buffers inside the current buffer and the recursive bit is set do the same
		// for the current buffer
		if((handle_to_buffer.first) && (recursive))
		begin
			`ifdef YAMM_USE_UVM
			`uvm_info("YAMM_INF", $sformatf("Inside buffer addressed at:%d - %d", handle_to_buffer.start_addr, handle_to_buffer.end_addr), UVM_MEDIUM)
			`uvm_info("YAMM_INF", "---", UVM_MEDIUM)
			`else
			$display("Inside buffer addressed at:%d - %d", handle_to_buffer.start_addr, handle_to_buffer.end_addr);
			$display("---");
			`endif
			handle_to_buffer.print(1);
			`ifdef YAMM_USE_UVM
			`uvm_info("YAMM_INF", "---", UVM_MEDIUM)
			`else
			$display("---");
			`endif
		end

		i++;
		handle_to_buffer = handle_to_buffer.next;
	end


endfunction

function string yamm_buffer::sprint_buffer(bit recursive=0, int identation=0);

	// Append the buffers parameters to the string
	sprint_buffer = $sformatf("@%08x:@%08x:%08x",this.start_addr, this.end_addr, this.size);

	if(this.is_free)
		sprint_buffer = $sformatf("%s \tFREE",sprint_buffer);
	else
		sprint_buffer = $sformatf("%s \tUSED",sprint_buffer);

	if(this.is_static)
		sprint_buffer = $sformatf("%s \tSTATIC",sprint_buffer);
	else
		sprint_buffer = $sformatf("%s \tNORMAL",sprint_buffer);

	sprint_buffer = $sformatf("%s %s",sprint_buffer, this.name);

	// If the recursive bit is set modify the indentation for each recursive level
	// and append all the buffers to the string
	if (recursive == 1 && first != null) begin
		yamm_buffer crt_buff = first;
		string ident="   ";
		for (int i=0; i<identation; i++) begin
			ident = $sformatf("%s   ",ident);
		end
		while (crt_buff != null) begin
			string buffer_info_child = crt_buff.sprint_buffer(recursive, identation+1);
			sprint_buffer = $sformatf("%s\n%s%s",sprint_buffer, ident, buffer_info_child);
			crt_buff = crt_buff.next;
		end
	end

endfunction


function void yamm_buffer::print_free();
	yamm_buffer handle_to_buffer;
	int i;
	handle_to_buffer = first_free;

	// Same as print but it traverses the free_buffers linked_list
	while(handle_to_buffer)
	begin
		$display("%0d . Size: %0d  Start_addr: %0d  End addr: %0d", i, handle_to_buffer.size, handle_to_buffer.start_addr, handle_to_buffer.end_addr);
		i++;
		handle_to_buffer = handle_to_buffer.next_free;
	end

endfunction

function real yamm_buffer::get_usage_statistics();
	yamm_buffer handle_to_buffer = first;
	real size_free_buffers = 0;
	real mem_size = 0;
	real usage_stats;

	// Check if there are any buffers
	if(handle_to_buffer == null)
		return 0;

	// Check if there are any free buffers
	if(!first_free)
		return 100;

	// Traverse the memory counting the size of free and used buffers
	while(handle_to_buffer)
	begin
		if(handle_to_buffer.is_free)
			size_free_buffers = size_free_buffers + handle_to_buffer.size;
		mem_size = mem_size + handle_to_buffer.size;
		handle_to_buffer = handle_to_buffer.next;
	end

	// Compute the usage value
	usage_stats = (mem_size-size_free_buffers)/mem_size * 100;
	return usage_stats;
endfunction

function real yamm_buffer::get_fragmentation();
	real frag;
	real number_of_buffers = this.number_of_buffers;
	real number_of_free_buffers = this.number_of_free_buffers;

	// Check if there are any occupied buffers
	if(number_of_buffers == 0)
		return 0;

	// If the number of occupied buffers is equal with the number of free buffers the frag is 100%
	if(number_of_free_buffers>=number_of_buffers)
		return 100;

	// Compute the fragmentation
	frag = number_of_free_buffers/number_of_buffers * 100;
	return frag;

endfunction

function void yamm_buffer:: print_stats();
	`ifdef YAMM_USE_UVM
	`uvm_info("YAMM_INF", $sformatf("Fragmentation: %06f", get_fragmentation()), UVM_LOW)
	`uvm_info("YAMM_INF", $sformatf("Used memory: %0f", get_usage_statistics()), UVM_LOW)
	`uvm_info("YAMM_INF", $sformatf("Number of occupied buffers: %0d", number_of_buffers), UVM_LOW)
	`uvm_info("YAMM_INF", $sformatf("Number of free buffers: %0d", number_of_free_buffers), UVM_LOW)
	`else
	$display("\n");
	$display("[YAMM_INF] Fragmentation: %0f", get_fragmentation());
	$display("[YAMM_INF] Used memory: %0f", get_usage_statistics());
	$display("[YAMM_INF] Number of occupied buffers: %0d", number_of_buffers);
	$display("[YAMM_INF] Number of free buffers: %0d \n", number_of_free_buffers);
	`endif
endfunction

`endif