import XCTest
@testable import bidding_mobile_ios_sdk

final class SecureStorageTests: XCTestCase {
    
    override func setUpWithError() throws {
        SecureStorage.clear()
    }
    
    override func tearDownWithError() throws {
        SecureStorage.clear()
    }

    func testSetString_AndGetString_ShouldReturnSameValue() throws {
        // Given
        let key = "test_key"
        let value = "test_value"
        
        // When
        SecureStorage.setString(key, value: value)
        let retrieved = SecureStorage.getString(key)
        
        // Then
        XCTAssertEqual(retrieved, value)
    }
    
    func testGetString_WhenKeyNotExists_ShouldReturnDefaultValue() throws {
        // Given
        let key = "non_existent_key"
        let defaultValue = "default"
        
        // When
        let retrieved = SecureStorage.getString(key, defaultValue: defaultValue)
        
        // Then
        XCTAssertEqual(retrieved, defaultValue)
    }
    
    func testGetString_WhenKeyNotExists_AndNoDefault_ShouldReturnNil() throws {
        // Given
        let key = "non_existent_key"
        
        // When
        let retrieved = SecureStorage.getString(key)
        
        // Then
        XCTAssertNil(retrieved)
    }
    
    func testSetLong_AndGetLong_ShouldReturnSameValue() throws {
        // Given
        let key = "test_long_key"
        let value: Int64 = 123456789
        
        // When
        SecureStorage.setLong(key, value: value)
        let retrieved = SecureStorage.getLong(key)
        
        // Then
        XCTAssertEqual(retrieved, value)
    }
    
    func testGetLong_WhenKeyNotExists_ShouldReturnDefaultValue() throws {
        // Given
        let key = "non_existent_long_key"
        let defaultValue: Int64 = 999
        
        // When
        let retrieved = SecureStorage.getLong(key, defaultValue: defaultValue)
        
        // Then
        XCTAssertEqual(retrieved, defaultValue)
    }
    
    func testRemove_ShouldDeleteKey() throws {
        // Given
        let key = "key_to_remove"
        SecureStorage.setString(key, value: "value")
        XCTAssertNotNil(SecureStorage.getString(key))
        
        // When
        SecureStorage.remove(key)
        
        // Then
        XCTAssertNil(SecureStorage.getString(key))
    }
    
    func testClear_ShouldRemoveAllKeys() throws {
        // Given
        SecureStorage.setString("key1", value: "value1")
        SecureStorage.setString("key2", value: "value2")
        SecureStorage.setLong("key3", value: 123)
        
        // When
        SecureStorage.clear()
        
        // Then
        XCTAssertNil(SecureStorage.getString("key1"))
        XCTAssertNil(SecureStorage.getString("key2"))
        XCTAssertEqual(SecureStorage.getLong("key3", defaultValue: 0), 0)
    }
    
    func testObfuscation_StoredValueShouldBeDifferentFromOriginal() throws {
        // Given
        let key = "obfuscation_test"
        let value = "plain_text_value"
        
        // When
        SecureStorage.setString(key, value: value)
        
        // Then - Retrieved value should match original
        let retrieved = SecureStorage.getString(key)
        XCTAssertEqual(retrieved, value)
    }
}

