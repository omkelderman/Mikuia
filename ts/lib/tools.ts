export class Tools {
    static chunkArray<T>(array: Array<T>, size: number): Array<Array<T>> {
        var R: Array<any> = [];
        var a = array.slice(0);
        while(a.length > 0) {
            R.push(a.splice(0, size));
        }
        return R;
    }
}