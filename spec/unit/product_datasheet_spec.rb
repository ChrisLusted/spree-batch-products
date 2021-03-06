require 'spec_helper'

describe Spree::ProductDatasheet do
  
  context 'with file attachments' do
    before(:each) do
      @not_deleted_product_datasheet = Spree::ProductDatasheet.new(:xls_file_name => 'does_not_exist.xls')
      @not_deleted_product_datasheet.save
      
      @deleted_product_datasheet = Spree::ProductDatasheet.new(:xls_file_name => 'does_not_exist.xls', :deleted_at => Time.now)
      @deleted_product_datasheet.save
    end
    
    it 'should return all ProductDatasheets with nil :deleted_at attribute on scope :not_deleted call' do
      collection = Spree::ProductDatasheet.not_deleted
      collection.should include(@not_deleted_product_datasheet)
      collection.should_not include(@deleted_product_datasheet)
    end
    
    it 'should return all ProductDatasheets with non-nil :deleted_at attribute on scope :deleted call' do
      collection = Spree::ProductDatasheet.deleted
      collection.should_not include(@not_deleted_product_datasheet)
      collection.should include(@deleted_product_datasheet)
    end
  end

  context 'in general' do
    before(:each) do
      @product_datasheet = Spree::ProductDatasheet.new
    end
    
    it 'should return the absolute path where it is located on #path call' do
      product_datasheet = Spree::ProductDatasheet.new(:xls_file_name => 'does_not_exist.xls')
      product_datasheet.id = 123456
      product_datasheet.path.should == "#{Rails.root}/uploads/product_datasheets/123456/does_not_exist.xls"
    end
    
    it 'should update its statistic attributes :before_save' do
      product_datasheet = Spree::ProductDatasheet.new(:xls_file_name => 'does_not_exist.xls')
      product_datasheet.save
      product_datasheet.matched_records.should_not be_nil
      product_datasheet.failed_records.should_not be_nil
      product_datasheet.updated_records.should_not be_nil
      product_datasheet.failed_queries.should_not be_nil
    end
    
    it 'should set its dummy tracking variables to 0 :after_find and :after_initialize' do
      product_datasheet = Spree::ProductDatasheet.new(:xls_file_name => 'does_not_exist.xls')
      product_datasheet.records_matched.should == 0
      product_datasheet.records_failed.should == 0
      product_datasheet.records_updated.should == 0
      product_datasheet.queries_failed.should == 0
    end

    it 'should return true on call to #processed? when :processed_at is not nil' do
      @product_datasheet.processed_at = Time.now
      @product_datasheet.processed?.should be_true
    end
    
    it 'should return false on call to #processed? when :processed_at is nil' do
      @product_datasheet.processed?.should be_false
    end
    
    it 'should return true on call to #deleted? when :deleted_at is not nil' do
      @product_datasheet.deleted_at = Time.now
      @product_datasheet.deleted?.should be_true
    end
    
    it 'should return false on call to #deleted? when :deleted_at is nil' do
      @product_datasheet.deleted?.should be_false
    end
    
    context 'creating new Products' do
    
      it 'should create a new Product when using a valid attr_hash' do
        attr_hash = {:name => 'test_product_name', :permalink => 'test-product-permalink', :price => 902.10}
        @product_datasheet.create_product(attr_hash)
        @product_datasheet.queries_failed.should == 0
      end
      
      it 'should increment @failed_queries when using an invalid attr_hash' do
        attr_hash = {}
        @product_datasheet.create_product(attr_hash)
        @product_datasheet.queries_failed.should == 1
      end
    end
    
    context 'creating new Variants' do
      
      it 'should create a new Variant when using a valid attr_hash' do
        product = Spree::Product.create({:name => 'test_product_name', :permalink => 'test-product-permalink', :price => 902.10})
        attr_hash = {:product_id => product.id}
        @product_datasheet.create_variant(attr_hash)
        @product_datasheet.queries_failed.should == 0
      end
      
      it 'should increment @failed_queries when using an invalid attr_hash' do
        attr_hash = {}
        @product_datasheet.create_variant(attr_hash)
        @product_datasheet.queries_failed.should == 1
      end
    end
    
    context 'updating Products' do
      before(:each) do
        @product = Spree::Product.create({:name => 'test_product_name', :permalink => 'test-product-permalink', :price => 902.10})
        @key = 'permalink'
        @value = 'test-product-permalink'
      end
      
      it 'should increment @failed_queries when the query returns an empty collection' do
        value = 'chunky bacon chunky bacon chunky bacon'
        attr_hash = {}
        @product_datasheet.update_products(@key, value, attr_hash)
        @product_datasheet.queries_failed.should == 1
      end
      
      it 'should add the size of the collection returned by the query to @records_matched' do
        attr_hash = {}
        @product_datasheet.update_products(@key, @value, attr_hash)
        @product_datasheet.records_matched.should == 1
      end
      
      it 'should increment @records_updated when the Product successfully updates with the attr_hash and saves' do
        attr_hash = {:price => 90210.00}
        @product_datasheet.update_products(@key, @value, attr_hash)
        @product.reload.price.to_f.should == 90210.00
        @product.master.reload.price.to_f.should == 90210.00
        @product_datasheet.records_updated.should == 1
      end
      
      it 'should increment @records_failed when the Product fails to save' do
        attr_hash = {:permalink => nil}
        @product_datasheet.update_products(@key, @value, attr_hash)
        @product_datasheet.records_failed.should == 1
      end
    end
    
    context 'updating Variants' do
      before(:each) do
        @product = Spree::Product.new({:name => 'test_product_name', :permalink => 'test-product-permalink', :sku => 'testvariantsku', :price => 902.10})
        @product.save
        @variant = @product.master

        @key = 'sku'
        @value = 'testvariantsku'
      end
      
      it 'should increment @failed_queries when the query returns an empty collection' do
        value = 'chunky bacon chunky bacon chunky bacon'
        attr_hash = {}
        @product_datasheet.update_variants(@key, value, attr_hash)
        @product_datasheet.queries_failed.should == 1
      end
      
      it 'should add the size of the collection returned by the query to @records_matched' do
        attr_hash = {}
        @product_datasheet.update_variants(@key, @value, attr_hash)
        @product_datasheet.records_matched.should == 1
      end
      
      it 'should increment @records_updated when the Variant successfully updates with the attr_hash and saves' do
        attr_hash = {:price => 90210.00}
        @product_datasheet.update_variants(@key, @value, attr_hash)
        @product_datasheet.records_updated.should == 1
        @variant.reload.price.to_f.should == 90210.00
        @product.reload.price.to_f.should == 90210.00
      end
      
      it 'should increment @records_failed when the Variant fails to save' do
        attr_hash = {:cost_price => 'not a number'}
        @product_datasheet.update_variants(@key, @value, attr_hash)
        @product_datasheet.records_failed.should == 1
      end
    end
  end
end
