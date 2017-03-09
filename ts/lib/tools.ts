export class Tools {
    static chunkArray(array: Array<any>, size: number): Array<any> {
        var R: Array<any> = [];
        var a = array.slice(0);
        while(a.length > 0) {
            R.push(a.splice(0, size));
        }
        return R;
    }
}