/* List of names for each instruction
 *
 * $Revision: 1.1.1.1 $
 * $Date: 2005/04/08 22:00:23 $
 */
#ifdef DEBUG
char *iname0[64] = {
    "halt","waiti","illegal","bpt","iot","illegal","illegal","illegal",
"illegal","illegal","illegal","illegal","illegal","illegal","illegal","illegal",
"illegal","illegal","illegal","illegal","illegal","illegal","illegal","illegal",
"illegal","illegal","illegal","illegal","illegal","illegal","illegal","illegal",
"illegal","illegal","illegal","illegal","illegal","illegal","illegal","illegal",
"illegal","illegal","illegal","illegal","illegal","illegal","illegal","illegal",
"illegal","illegal","illegal","illegal","illegal","illegal","illegal","illegal",
"illegal","illegal","illegal","illegal","illegal","illegal","illegal","illegal"
};

char *iname1[64] = {
    "rts","rts","rts","rts","rts","rts","rts","rts",
"illegal","illegal","illegal","illegal","illegal","illegal","illegal","illegal",
"illegal","illegal","illegal","illegal","illegal","illegal","illegal","illegal",
"illegal","illegal","illegal","illegal","illegal","illegal","illegal","illegal",
    "ccc","ccc","ccc","ccc","ccc","ccc","ccc","ccc",
    "ccc","ccc","ccc","ccc","ccc","ccc","ccc","ccc",
    "scc","scc","scc","scc","scc","scc","scc","scc",
    "scc","scc","scc","scc","scc","scc","scc","scc"
};

char *iname[1024] = {
    "dositab0","jmp","dositab1","swabi","br","br","br","br",
    "bne","bne","bne","bne","beq","beq","beq","beq",
    "bge","bge","bge","bge","blt","blt","blt","blt",
    "bgt","bgt","bgt","bgt","ble","ble","ble","ble",
    "jsr","jsr","jsr","jsr","jsr","jsr","jsr","jsr",
    "clr","com","inc","dec","neg","adc","sbc","tst",
    "ror","rol","asr","asl","mark","mfpi","mtpi","sxt",
"illegal","illegal","illegal","illegal","illegal","illegal","illegal","illegal",
    "mov","mov","mov","mov","mov","mov","mov","mov",
    "mov","mov","mov","mov","mov","mov","mov","mov",
    "mov","mov","mov","mov","mov","mov","mov","mov",
    "mov","mov","mov","mov","mov","mov","mov","mov",
    "mov","mov","mov","mov","mov","mov","mov","mov",
    "mov","mov","mov","mov","mov","mov","mov","mov",
    "mov","mov","mov","mov","mov","mov","mov","mov",
    "mov","mov","mov","mov","mov","mov","mov","mov",
    "cmp","cmp","cmp","cmp","cmp","cmp","cmp","cmp",
    "cmp","cmp","cmp","cmp","cmp","cmp","cmp","cmp",
    "cmp","cmp","cmp","cmp","cmp","cmp","cmp","cmp",
    "cmp","cmp","cmp","cmp","cmp","cmp","cmp","cmp",
    "cmp","cmp","cmp","cmp","cmp","cmp","cmp","cmp",
    "cmp","cmp","cmp","cmp","cmp","cmp","cmp","cmp",
    "cmp","cmp","cmp","cmp","cmp","cmp","cmp","cmp",
    "cmp","cmp","cmp","cmp","cmp","cmp","cmp","cmp",
    "bit","bit","bit","bit","bit","bit","bit","bit",
    "bit","bit","bit","bit","bit","bit","bit","bit",
    "bit","bit","bit","bit","bit","bit","bit","bit",
    "bit","bit","bit","bit","bit","bit","bit","bit",
    "bit","bit","bit","bit","bit","bit","bit","bit",
    "bit","bit","bit","bit","bit","bit","bit","bit",
    "bit","bit","bit","bit","bit","bit","bit","bit",
    "bit","bit","bit","bit","bit","bit","bit","bit",
    "bic","bic","bic","bic","bic","bic","bic","bic",
    "bic","bic","bic","bic","bic","bic","bic","bic",
    "bic","bic","bic","bic","bic","bic","bic","bic",
    "bic","bic","bic","bic","bic","bic","bic","bic",
    "bic","bic","bic","bic","bic","bic","bic","bic",
    "bic","bic","bic","bic","bic","bic","bic","bic",
    "bic","bic","bic","bic","bic","bic","bic","bic",
    "bic","bic","bic","bic","bic","bic","bic","bic",
    "bis","bis","bis","bis","bis","bis","bis","bis",
    "bis","bis","bis","bis","bis","bis","bis","bis",
    "bis","bis","bis","bis","bis","bis","bis","bis",
    "bis","bis","bis","bis","bis","bis","bis","bis",
    "bis","bis","bis","bis","bis","bis","bis","bis",
    "bis","bis","bis","bis","bis","bis","bis","bis",
    "bis","bis","bis","bis","bis","bis","bis","bis",
    "bis","bis","bis","bis","bis","bis","bis","bis",
    "add","add","add","add","add","add","add","add",
    "add","add","add","add","add","add","add","add",
    "add","add","add","add","add","add","add","add",
    "add","add","add","add","add","add","add","add",
    "add","add","add","add","add","add","add","add",
    "add","add","add","add","add","add","add","add",
    "add","add","add","add","add","add","add","add",
    "add","add","add","add","add","add","add","add",
    "mul","mul","mul","mul","mul","mul","mul","mul",
    "divide","divide","divide","divide","divide","divide","divide","divide",
    "ash","ash","ash","ash","ash","ash","ash","ash",
    "ashc","ashc","ashc","ashc","ashc","ashc","ashc","ashc",
    "xor","xor","xor","xor","xor","xor","xor","xor",
"illegal","illegal","illegal","illegal","illegal","illegal","illegal","illegal",
"illegal","illegal","illegal","illegal","illegal","illegal","illegal","illegal",
    "sob","sob","sob","sob","sob","sob","sob","sob",
    "bpl","bpl","bpl","bpl","bmi","bmi","bmi","bmi",
    "bhi","bhi","bhi","bhi","blos","blos","blos","blos",
    "bvc","bvc","bvc","bvc","bvs","bvs","bvs","bvs",
    "bcc","bcc","bcc","bcc","bcs","bcs","bcs","bcs",
    "emt","emt","emt","emt","trap","trap","trap","trap",
    "clrb","comb","incb","decb","negb","adcb","sbcb","tstb",
    "rorb","rolb","asrb","aslb","mtps","mfpd","mtpd","mfps",
"illegal","illegal","illegal","illegal","illegal","illegal","illegal","illegal",
    "movb","movb","movb","movb","movb","movb","movb","movb",
    "movb","movb","movb","movb","movb","movb","movb","movb",
    "movb","movb","movb","movb","movb","movb","movb","movb",
    "movb","movb","movb","movb","movb","movb","movb","movb",
    "movb","movb","movb","movb","movb","movb","movb","movb",
    "movb","movb","movb","movb","movb","movb","movb","movb",
    "movb","movb","movb","movb","movb","movb","movb","movb",
    "movb","movb","movb","movb","movb","movb","movb","movb",
    "cmpb","cmpb","cmpb","cmpb","cmpb","cmpb","cmpb","cmpb",
    "cmpb","cmpb","cmpb","cmpb","cmpb","cmpb","cmpb","cmpb",
    "cmpb","cmpb","cmpb","cmpb","cmpb","cmpb","cmpb","cmpb",
    "cmpb","cmpb","cmpb","cmpb","cmpb","cmpb","cmpb","cmpb",
    "cmpb","cmpb","cmpb","cmpb","cmpb","cmpb","cmpb","cmpb",
    "cmpb","cmpb","cmpb","cmpb","cmpb","cmpb","cmpb","cmpb",
    "cmpb","cmpb","cmpb","cmpb","cmpb","cmpb","cmpb","cmpb",
    "cmpb","cmpb","cmpb","cmpb","cmpb","cmpb","cmpb","cmpb",
    "bitb","bitb","bitb","bitb","bitb","bitb","bitb","bitb",
    "bitb","bitb","bitb","bitb","bitb","bitb","bitb","bitb",
    "bitb","bitb","bitb","bitb","bitb","bitb","bitb","bitb",
    "bitb","bitb","bitb","bitb","bitb","bitb","bitb","bitb",
    "bitb","bitb","bitb","bitb","bitb","bitb","bitb","bitb",
    "bitb","bitb","bitb","bitb","bitb","bitb","bitb","bitb",
    "bitb","bitb","bitb","bitb","bitb","bitb","bitb","bitb",
    "bitb","bitb","bitb","bitb","bitb","bitb","bitb","bitb",
    "bicb","bicb","bicb","bicb","bicb","bicb","bicb","bicb",
    "bicb","bicb","bicb","bicb","bicb","bicb","bicb","bicb",
    "bicb","bicb","bicb","bicb","bicb","bicb","bicb","bicb",
    "bicb","bicb","bicb","bicb","bicb","bicb","bicb","bicb",
    "bicb","bicb","bicb","bicb","bicb","bicb","bicb","bicb",
    "bicb","bicb","bicb","bicb","bicb","bicb","bicb","bicb",
    "bicb","bicb","bicb","bicb","bicb","bicb","bicb","bicb",
    "bicb","bicb","bicb","bicb","bicb","bicb","bicb","bicb",
    "bisb","bisb","bisb","bisb","bisb","bisb","bisb","bisb",
    "bisb","bisb","bisb","bisb","bisb","bisb","bisb","bisb",
    "bisb","bisb","bisb","bisb","bisb","bisb","bisb","bisb",
    "bisb","bisb","bisb","bisb","bisb","bisb","bisb","bisb",
    "bisb","bisb","bisb","bisb","bisb","bisb","bisb","bisb",
    "bisb","bisb","bisb","bisb","bisb","bisb","bisb","bisb",
    "bisb","bisb","bisb","bisb","bisb","bisb","bisb","bisb",
    "bisb","bisb","bisb","bisb","bisb","bisb","bisb","bisb",
    "sub","sub","sub","sub","sub","sub","sub","sub",
    "sub","sub","sub","sub","sub","sub","sub","sub",
    "sub","sub","sub","sub","sub","sub","sub","sub",
    "sub","sub","sub","sub","sub","sub","sub","sub",
    "sub","sub","sub","sub","sub","sub","sub","sub",
    "sub","sub","sub","sub","sub","sub","sub","sub",
    "sub","sub","sub","sub","sub","sub","sub","sub",
    "sub","sub","sub","sub","sub","sub","sub","sub",
    "fpset","ldfps","stfps","stst","clrf","tstf","absf","negf",
    "mulf","mulf","mulf","mulf","moddf","moddf","moddf","moddf",
    "addf","addf","addf","addf","ldf","ldf","ldf","ldf",
    "subf","subf","subf","subf","cmpf","cmpf","cmpf","cmpf",
    "stf","stf","stf","stf","divf","divf","divf","divf",
    "stexp","stexp","stexp","stexp","stcfi","stcfi","stcfi","stcfi",
    "stcdf","stcdf","stcdf","stcdf","ldexpp","ldexpp","ldexpp","ldexpp",
    "lcdif","lcdif","lcdif","lcdif","ldcdf","ldcdf","ldcdf","ldcdf"
};
#endif
