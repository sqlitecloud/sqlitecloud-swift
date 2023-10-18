//
//  SQLiteCloud
//
//  Created by Dimitri Giani.
//
//  Copyright (c) 2023 SQLite Cloud, Inc. (https://sqlitecloud.io/)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import Foundation
import CSQCloud

/// The `SQLiteCloudVM` class provides an interface for executing SQL statements with the SQLite Cloud
/// backend server. It allows you to prepare, bind, and step through SQL statements, retrieve data,
/// and handle errors. It compiles an SQL statement into a byte-code virtual machine.
///
/// - Note: This class wraps the underlying SQLite Cloud Virtual Machine C functions and simplifies
///  its usage in Swift.
///
/// ## Initialization
/// To use `SQLiteCloudVM`, create an instances of this class using the `SQLiteCloud`
/// actor's `compile(query:)` method, which compiles SQL queries into virtual machines.
///
/// Example usage:
///
/// ```swift
/// import SQLiteCloud
/// let query = "SELECT * FROM your_table"
/// let vm = try await sqliteCloud.compile(query: query)
/// ```
public final class SQLiteCloudVM: Sendable {
    private let vm: OpaquePointer

    init(vm: OpaquePointer) {
        self.vm = vm
    }
}

public extension SQLiteCloudVM {
    /// Binds a value to a parameter in the compiled SQL query represented by this virtual machine.
    ///
    /// Use this method to bind different types of values, such as integers, strings, blobs, or
    /// nulls, to parameters in a compiled SQL query. The query is executed when you call
    /// the `step()` method on the virtual machine.
    ///
    /// - Parameters:
    ///    - value: The value to bind to the parameter.
    ///    - index: The index of the parameter in the SQL query.
    ///
    /// - Returns: A boolean indicating whether the binding was successful.
    /// - Throws: An error of type `SQLiteCloudError` if there is an issue with the binding 
    ///           operation or if the parameter index is out of bounds
    ///
    /// Example usage:
    ///
    /// ```swift
    /// do {
    ///      // Create a virtual machine.
    ///      let query = "INSERT INTO employees (name, age) VALUES (?1, ?2)"
    ///      let vm = try await sqliteCloud.compile(query: query)
    ///      // Bind values to parameters in the SQL query.
    ///      let name = "John Doe"
    ///      let age = 30
    ///      let isBindingSuccessful = try await vm.bindValue(.string(name), index: 1) &&
    ///                                try await vm.bindValue(.integer(age), index: 2)
    ///      // Execute the query using the virtual machine.
    ///      if isBindingSuccessful {
    ///          try await vm.step()
    ///      }
    ///  } catch {
    ///      // Handle any errors that occur during the binding or execution.
    ///      print("Error: \(error)")
    ///  }
    /// ```
    func bindValue(_ value: SQLiteCloudVMValue, index: Int) async throws -> Bool {
        let rowIndex = Int32(index)
        var success: Bool = false

        switch value {
        case .integer(let int):
            success = SQCloudVMBindInt(vm, rowIndex, Int32(int))

        case .integer64(let int):
            success = SQCloudVMBindInt64(vm, rowIndex, int)

        case .double(let double):
            success = SQCloudVMBindDouble(vm, rowIndex, double)

        case .string(let string):
            success = SQCloudVMBindText(vm, rowIndex, string, Int32(value.strlen))

        case .blob(let data):
            var theData = data
            success = theData.withUnsafeMutableBytes { pointer in
                let bufferPointer = pointer.baseAddress!.assumingMemoryBound(to: UInt8.self)
                let rawPtr = UnsafeMutableRawPointer(bufferPointer)

                return SQCloudVMBindBlob(vm, rowIndex, rawPtr, Int32(data.count))
            }

        case .blobZero:
            success = SQCloudVMBindZeroBlob(vm, rowIndex, 0)

        case .null:
            success = SQCloudVMBindNull(vm, rowIndex)
        }

        return success
    }

    /// Executes a single step in a prepared SQLite query. This method advances the virtual
    /// machine's program counter, processing the next operation in the SQLite query.
    ///
    /// This method is used when working with a prepared SQLite query in a virtual machine 
    /// (VM). It advances the VM's program counter and performs the next operation in the
    /// query. If an error occurs during execution, a corresponding error is thrown,
    /// encapsulated within a `SQLiteCloudError`.
    ///
    /// - Throws: An error of type `SQLiteCloudError` if an issue occurs during the execution
    ///           of the query.
    func step() async throws {
        let result = SQCloudVMStep(vm)

        if result == RESULT_ERROR {
            throw SQLiteCloudError.handleVMError(vm: vm)
        }
    }

    /// Retrieves all values from the current row of a virtual machine (VM) that 
    /// represents the result of an SQLite query.
    ///
    /// This method fetches all the values from the current row of the virtual machine. 
    /// It's useful when working with the results of a prepared SQLite query. The
    /// values are returned as an array of `SQLiteCloudVMValue` objects.
    ///
    /// - Throws: An error of type `SQLiteCloudError` if an issue occurs while 
    ///           retrieving the values.
    ///
    /// - Returns: An array of `SQLiteCloudVMValue` objects, each representing a value 
    ///            in the current row of the SQLite query result.
    func getValues() async throws -> [SQLiteCloudVMValue] {
        let columnCount = try await columnCount()

        var rows: [SQLiteCloudVMValue] = []

        for index in 0..<columnCount {
            let value = try await getValueAt(index: Int(index))
            rows.append(value)
        }

        return rows
    }

    /// Retrieves the value at a specified column index from the current row of a 
    /// virtual machine (VM) representing an SQLite query result.
    ///
    /// This method fetches the value at the specified column index in the current 
    /// row of the virtual machine. The retrieved value is returned as an
    /// `SQLiteCloudVMValue` object.
    ///
    /// - Parameters:
    ///   - index: The zero-based index of the column to retrieve the value from.
    ///
    /// - Throws: An error of type `SQLiteCloudError` if an issue occurs while retrieving 
    ///           the value or if the value's type is unsupported.
    ///
    /// - Returns: An `SQLiteCloudVMValue` object representing the value at the specified 
    ///            column index in the current row of the SQLite query result.
    func getValueAt(index: Int) async throws -> SQLiteCloudVMValue {
        let valueType = try await columnType(index: index)

        switch valueType {
        case .integer:
            return intergerValueAt(index: index)

        case .float:
            return doubleValueAt(index: index)

        case .text:
            return textValueAt(index: index)

        case .blob:
            return blobValueAt(index: index)

        case .null:
            return nullValueAt(index: index)

        default:
            throw SQLiteCloudError.executionFailed(.unsupportedResultType)
        }
    }

    /// Closes a SQLite virtual machine (VM) associated with a prepared statement.
    ///
    /// This method is used to close a virtual machine (VM) that was previously 
    /// prepared for executing an SQLite query. Closing the VM releases any resources
    /// associated with it and finalizes the prepared statement.
    ///
    /// - Throws: An error of type `SQLiteCloudError` if an issue occurs while closing
    ///           the VM.
    ///
    /// - Note: Closing the VM is important to free up resources and maintain the 
    ///         integrity of the SQLite database.
    func close() async throws {
        let success = SQCloudVMClose(vm)

        if success == false {
            throw SQLiteCloudError.handleVMError(vm: vm)
        }
    }
}

public extension SQLiteCloudVM {
    /// Returns the number of columns in the result set of the executed query.
    ///
    /// This method retrieves the count of columns in the result set produced 
    /// by the most recent execution of the SQL query. It is typically used
    /// after executing a query to determine the number of columns in the result set.
    ///
    /// - Returns: An `Int32` value representing the number of columns in the result set.
    func columnCount() async throws -> Int32 {
        SQCloudVMColumnCount(vm)
    }
    /// Returns the identifier of the last inserted row.
    ///
    /// This method retrieves the identifier (row ID) of the last row inserted into
    /// the database. It is useful for retrieving the primary key value of the most
    /// recently added record.
    ///
    /// - Returns: An `Int64` value representing the identifier (row ID) of the last
    ///            inserted row.
    func lastRowID() async throws -> Int64 {
        SQCloudVMLastRowID(vm)
    }

    /// Retrieves the number of rows that were modified, inserted, or deleted by the
    /// most recent query execution.
    ///
    /// This method returns the total number of rows inserted, modified or deleted by all
    /// INSERT, UPDATE or DELETE statements completed since the database connection was
    /// opened, including those executed as part of trigger programs. Executing any other
    /// type of SQL statement does not affect the value returned by this method.
    /// Changes made as part of foreign key actions are included in the count, but those
    /// made as part of REPLACE constraint resolution are not. Changes to a view that are
    /// intercepted by INSTEAD OF triggers are not counted.
    ///
    /// - Note: If you need to get the total changes from a SQCloudConnection object
    ///         you can send a DATABASE GET TOTAL CHANGES command.
    ///
    /// - Returns: An `Int64` value representing the number of rows that were modified, 
    ///            inserted, or deleted.
    func changes() async throws -> Int64 {
        SQCloudVMChanges(vm)
    }

    /// Retrieves the total number of rows that were modified, inserted, or deleted 
    /// since the database connection was opened.
    ///
    /// This method returns the total number of rows that were modified, inserted, or 
    /// deleted since the database connection was opened. It provides a cumulative count
    /// of changes made during the current database connection.
    ///
    /// - Returns: An `Int64` value representing the total number of rows that were
    ///            modified, inserted, or deleted since the database connection was opened.
    func totalChanges() async throws -> Int64 {
        SQCloudVMTotalChanges(vm)
    }

    /// Checks whether the virtual machine is read-only.
    ///
    /// This method returns true if and only if the prepared statement bound to vm makes
    /// no direct changes to the content of the database file. This routine returns false
    /// if there is any possibility that the statement might change the database file.
    /// A false return does not guarantee that the statement will change the database file.
    ///
    /// - Returns: `true` if the virtual machine is in read-only mode, `false` otherwise.
    func isReadOnly() async throws -> Bool {
        SQCloudVMIsReadOnly(vm)
    }

    /// Checks whether the virtual machine is in "EXPLAIN" mode.
    ///
    /// This method returns 1 if the prepared statement is an EXPLAIN statement,
    /// or 2 if the statement S is an EXPLAIN QUERY PLAN. This method returns 0 if
    /// the statement is an ordinary statement or a NULL pointer.
    ///
    /// - Returns: An `Int32` value indicating whether the virtual machine is in "EXPLAIN" mode.
    func isExplain() async throws -> Int32 {
        SQCloudVMIsExplain(vm)
    }

    /// Checks whether the virtual machine has been finalized.
    ///
    /// This method returns true if the prepared statement bound to the vm has been
    /// stepped at least once but has neither run to completion nor been reset.
    ///
    /// - Returns: `true` if the virtual machine has been finalized, `false` otherwise.
    func isFinalized() async throws -> Bool {
        SQCloudVMIsFinalized(vm)
    }

    /// Retrieves the number of SQL parameters in a prepared statement.
    ///
    /// This method can be used to find the number of SQL parameters in a prepared statement.
    /// SQL parameters are tokens of the form "?", "?NNN", ":AAA", "$AAA", or "@AAA" that
    /// serve as placeholders for values that are bound to the parameters at a later time.
    /// This method actually returns the index of the largest (rightmost) parameter. For
    /// all forms except ?NNN, this will correspond to the number of unique parameters.
    /// If parameters of the ?NNN form are used, there may be gaps in the list.
    ///
    /// - Returns: An `Int32` value representing the number of parameters in a prepared statement.
    func bindParameterCount() async throws -> Int32 {
        SQCloudVMBindParameterCount(vm)
    }

    /// Retrieves the index of a parameter by its name.
    ///
    /// This method retrieves the index of a parameter by its name. It is typically used
    /// to find the index of a named parameter that can be subsequently bound to a value
    /// using the `bindValue` method.
    ///
    /// - Parameter name: The name of the parameter to find.
    /// - Returns: An `Int32` value representing the index of the specified parameter.
    func bindParameterIndex(name: String) async throws -> Int32 {
        SQCloudVMBindParameterIndex(vm, name)
    }

    /// Retrieves the name of a parameter by its index.
    ///
    /// This method retrieves the name of a parameter by its index. It is typically used 
    /// to find the name of a parameter after specifying it by index with the
    /// `bindParameterIndex` method.
    ///
    /// - Parameter index: The index of the parameter for which the name is to be determined.
    ///
    /// - Throws: An error of type `SQLiteCloudError` if an issue occurs while retrieving 
    ///           the parameter name. The error may indicate an invalid parameter index.
    ///
    /// - Returns: A `String` value representing the name of the specified parameter.
    func bindParameterName(index: Int) async throws -> String {
        guard let value = SQCloudVMBindParameterName(vm, Int32(index)) else {
            throw SQLiteCloudError.virtualMachineFailure(.invalidParameterIndex(index: index))
        }
        
        return String(cString: value)
    }

    /// Retrieves the data type of a column by its index.
    ///
    /// This method retrieves the data type of a column in the result set by its index. 
    /// It returns an enumeration value representing the type of data stored in the specified column.
    ///
    /// - Parameter index: The index of the column for which the data type is to be determined.
    ///
    /// - Returns: An `SQLiteCloudValueType` enumeration value representing the data type of
    ///           the specified column.
    func columnType(index: Int) async throws -> SQLiteCloudValueType {
        let valueType = SQCloudVMColumnType(vm, Int32(index))
        return SQLiteCloudValueType(rawValue: Int(valueType.rawValue)) ?? .unknown
    }

    /// Retrieves the name of a column by its index.
    ///
    /// This method retrieves the name of a column in the result set by its index. 
    /// It returns the name as a string.
    ///
    /// - Parameter index: The index of the column for which the name is to be determined.
    ///
    /// - Returns: A `String` value representing the name of the specified column.
    func columnName(index: Int) async throws -> String {
        let result = SQCloudVMResult(vm)
        var len: Int32 = 0
        if let value = SQCloudRowsetColumnName(result, UInt32(index), &len) {
            return String(format: "%.*s", len, value)
        }
        return ""
    }
}

public extension SQLiteCloudVM {
    /// Retrieves an integer value at the specified column index.
    ///
    /// This method retrieves an integer value at the specified column index from 
    /// the current row of the virtual machine's result set.
    ///
    /// - Parameter index: The index of the column to retrieve.
    ///
    /// - Returns: A `SQLiteCloudVMValue` containing the integer value found at 
    ///            the specified column index.
    func intergerValueAt(index: Int) -> SQLiteCloudVMValue {
        .integer64(SQCloudVMColumnInt64(vm, Int32(index)))
    }

    /// Retrieves a double value at the specified column index.
    ///
    /// This method retrieves a double value at the specified column index from the 
    /// current row of the virtual machine's result set.
    ///
    /// - Parameter index: The index of the column to retrieve.
    ///
    /// - Returns: A `SQLiteCloudVMValue` containing the double value found at the 
    ///            specified column index.
    func doubleValueAt(index: Int) -> SQLiteCloudVMValue {
        .double(SQCloudVMColumnDouble(vm, Int32(index)))
    }

    /// Retrieves a text (string) value at the specified column index.
    ///
    /// This method retrieves a text (string) value at the specified column index 
    /// from the current row of the virtual machine's result set.
    ///
    /// - Parameter index: The index of the column to retrieve.
    ///
    /// - Returns: A `SQLiteCloudVMValue` containing the text (string) value found 
    ///            at the specified column index.
    func textValueAt(index: Int) -> SQLiteCloudVMValue {
        var len: UInt32 = 0
        if let chars = SQCloudVMColumnText(vm, Int32(index), &len) {
            return .string(String(cString: chars))
        } else {
            return .string("")
        }
    }

    /// Retrieves a blob (binary data) value at the specified column index.
    ///
    /// This method retrieves a blob (binary data) value at the specified column 
    /// index from the current row of the virtual machine's result set.
    ///
    /// - Parameter index: The index of the column to retrieve.
    ///
    /// - Returns: A `SQLiteCloudVMValue` containing the blob (binary data) value 
    ///            found at the specified column index.
    func blobValueAt(index: Int) -> SQLiteCloudVMValue {
        var len: UInt32 = 0
        if let buffer = SQCloudVMColumnBlob(vm, Int32(index), &len) {
            return .blob(Data(bytes: buffer, count: Int(len)))
        }
        
        return .blob(.empty)
    }

    /// Retrieves a null value at the specified column index.
    ///
    /// This method retrieves a null value at the specified column index from the 
    /// current row of the virtual machine's result set.
    ///
    /// - Parameter index: The index of the column to retrieve.
    ///
    /// - Returns: A `SQLiteCloudVMValue` containing a null value.
    func nullValueAt(index: Int) -> SQLiteCloudVMValue {
        .null
    }
}
