//
//  Matrix.swift
//  WorldMatrix
//
//  Created by Alexandre Joly on 14/10/15.
//  Copyright © 2015 KiloKilo GmbH. All rights reserved.
//

struct Matrix<T> {

    let rows: Int, columns: Int
    var grid: [T]

    init(rows: Int, columns: Int, repeatedValue: T) {
        self.rows = rows
        self.columns = columns
        grid = Array<T>(count: rows * columns, repeatedValue: repeatedValue)
    }

    init(columns:Int, array:Array<T>) {
        grid = array
        self.columns = columns
        self.rows = grid.count / columns

        assert(rows * columns == grid.count, "Array is not complete. Array should have \(columns) * x elements")
    }


    func indexIsValidForRow(row: Int, column: Int) -> Bool {
        return row >= 0 && row < rows && column >= 0 && column < columns
    }


    subscript(row: Int, column: Int) -> T {
        get {
            assert(indexIsValidForRow(row, column: column), "Index out of range")
            return grid[(row * columns) + column]
        }
        set {
            assert(indexIsValidForRow(row, column: column), "Index out of range")
            grid[(row * columns) + column] = newValue
        }
    }


    func toString() -> String {
        var output = ""

        output = "["

        for row in 0..<rows {

//            output += "\n  ["
            output += "\n"

            for column in 0..<columns {

                output += "\(grid[(row * columns) + column])"

                guard column + 1 < columns || row + 1 < rows else { continue }
                output += ", "

            }

//            output += "]"

//            guard row + 1 < rows else { continue }
//            output += ", "
        }

        output += "\n]"

        return output
    }
}

extension Matrix: CollectionType {
    typealias Index = Int

    var startIndex: Index {
        get {
            return 0
        }
    }
    var endIndex: Index {
        get {
            return grid.count
        }
    }

    subscript (_i: Index) -> (row:Int, column:Int, element:T) {
        get {
            let rowColumn = getRowColumnForIndex(_i)

            return (rowColumn.row, rowColumn.column, grid[_i])
        }
    }

    private func getRowColumnForIndex(index: Index) -> (row:Int, column:Int) {
        let row:Int = index / columns
        let column:Int = index % columns

        return (row, column)
    }
}