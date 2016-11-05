//
//  Matrix.swift
//  WorldMatrix
//
//  Created by Alexandre Joly on 14/10/15.
//  Copyright © 2015 KiloKilo GmbH. All rights reserved.
//

public struct Matrix<T> {

    let rows: Int, columns: Int
    var grid: [T]

    public init(rows: Int, columns: Int, repeatedValue: T) {
        self.rows = rows
        self.columns = columns
        grid = Array<T>(repeating: repeatedValue, count: rows * columns)
    }

    public init(columns:Int, array:Array<T>) {
        grid = array
        self.columns = columns
        self.rows = grid.count / columns

        assert(rows * columns == grid.count, "Array is not complete. Array should have \(columns) * x elements")
    }


    public func indexIsValidForRow(_ row: Int, column: Int) -> Bool {
        return row >= 0 && row < rows && column >= 0 && column < columns
    }


    public subscript(row: Int, column: Int) -> T {
        get {
            assert(indexIsValidForRow(row, column: column), "Index out of range")
            return grid[(row * columns) + column]
        }
        set {
            assert(indexIsValidForRow(row, column: column), "Index out of range")
            grid[(row * columns) + column] = newValue
        }
    }

    public func last() -> T? {
        return grid.last
    }

}

extension Matrix: Collection {

    public typealias Index = Int

    public var startIndex: Index {
        get {
            return 0
        }
    }
    public var endIndex: Index {
        get {
            return grid.count
        }
    }
    
    /// Returns the position immediately after the given index.
    ///
    /// - Parameter i: A valid index of the collection. `i` must be less than
    ///   `endIndex`.
    /// - Returns: The index value immediately after `i`.
    public func index(after i: Int) -> Int {
        return i + 1
    }

    public subscript (_i: Index) -> (row:Int, column:Int, element:T) {
        get {
            let rowColumn = getRowColumnForIndex(_i)
            return (rowColumn.row, rowColumn.column, grid[_i])
        }
    }

    fileprivate func getRowColumnForIndex(_ index: Index) -> (row:Int, column:Int) {
        let row:Int = index / columns
        let column:Int = index % columns

        return (row, column)
    }
}
