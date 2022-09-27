const person = @import("./person.zig");

pub fn Company() type {
    return struct {
        const Self = @This();

        name: []u8,
        address: []u8,
        employees: []person.Person(),

        pub fn getFirstEmployeeName(self: *Self) []u8 {
            if (self.employees.len == 0) {
                return "";
            }
            return self.employees[0].name;
        }
    };
}

pub fn new_company(name: []u8, address: []u8, employees: person.People) Company() {
    return .{
        .name = name,
        .address = address,
        .employees = employees,
    };
}