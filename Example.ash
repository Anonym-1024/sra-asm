header {
    // product name
    name: MyProgram

    
    // exec - executable, lib - library
    product: exec
}

compile {
    Example.asm
}

link {
    [#Math]
    [#12, /.../DynamicLib.asl]
}


include {
    /.../StaticLib.asl
}
