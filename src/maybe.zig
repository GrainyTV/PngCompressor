pub fn Maybe(comptime T: type) type
{
    return struct
    {
        value: ?T = null,
        
        pub fn HasValue(this: *const @This()) bool
        {
            return if (this.value) |_| true else false;
        }
    };
}