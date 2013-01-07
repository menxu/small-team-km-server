require 'spec_helper'

describe '数据列表' do
  let(:ben7th) {FactoryGirl.create :user}
  let(:lifei) {FactoryGirl.create :user, :with_data_lists}
  before(:each) do
    # lifei 会创建一共 34 个，2+32
    # 2 个 演示 data_list
    # 32 个 FactoryGirl 创建的
    lifei.data_lists
    # ben7th 会创建 2 个 演示 data_list
    ben7th.data_lists
  end

  describe '个人动作' do
    it '创建新用户的时候，会给用户创建两个演示列表' do
      DataList.count.should == 36
    end

    it '用户可以创建一个列表' do
      DataList.count.should == 36

      ben7th.data_lists.count.should == 2
      ben7th.data_lists.create :title => '我的列表',
                               :kind => 'COLLECTION'
      ben7th.data_lists.count.should == 3

      DataList.count.should == 37
      DataList.last.creator.should == ben7th
    end

    it '可以分别查询用户的两种不同类型的列表' do

      lifei.data_lists.count.should_not == 0

      count_collection = lifei.data_lists.with_kind_collection.count
      count_step = lifei.data_lists.with_kind_step.count

      count_collection.should_not == 0
      count_collection.should_not == 0

      lifei.data_lists.create :title => '我的列表',
                              :kind => 'COLLECTION'

      lifei.data_lists.with_kind_collection.count.should == count_collection + 1
    end

    describe '用户可以在列表中创建列表项' do
      it '用户可以创建 URL 类型的列表项' do
        data_list = lifei.data_lists.last
        
        data_list.create_item('URL', 'ben7th的微博', 'http://weibo.com/ben7th')
        data_list.create_item('URL', '负伤的骑士的微博', 'http://weibo.com/fushang318')

        data_list.data_items.count.should == 2
      end

      it '用户可以创建 IMAGE 类型的列表项' do
        data_list = lifei.data_lists.last

        image1 = File.new File.join(Rails.root, 'spec/factories/test.png')
        image2 = File.new File.join(Rails.root, 'spec/factories/test.png')

        data_list.create_item('IMAGE', '图一', image1)
        data_list.create_item('IMAGE', '图二', image1)
        data_list.data_items.count.should == 2
      end

      it '用户可以创建 TEXT 类型的列表项' do
        data_list = lifei.data_lists.last

        data_list.create_item('TEXT', 'haha', '哈哈哈哈哈')
        data_list.create_item('TEXT', 'hehe', '呵呵呵呵嘿')
        data_list.data_items.count.should == 2
      end

      it '列表项标题不能重复' do
        data_list = lifei.data_lists.last

        data_list.create_item('IMAGE', 'haha', '哈哈哈哈哈')
        data_list.data_items.count.should == 1

        expect {
          data_list.create_item('IMAGE', 'haha', '呵呵呵呵嘿')
        }.to raise_error(DataItem::TitleRepeatError)
        data_list.data_items.count.should == 1
      end

      it '列表项URL不能重复' do
        data_list = lifei.data_lists.last

        data_list.create_item('URL', 'ben7th的微博', 'http://weibo.com/ben7th')
        data_list.data_items.count.should == 1

        expect {
          data_list.create_item('URL', '负伤的骑士的微博', 'http://weibo.com/ben7th')
        }.to raise_error(DataItem::UrlRepeatError)
        data_list.data_items.count.should == 1
      end

      it '用户可以选择某个列表 不分享 或 分享，如果选择分享则列表进入 public_timeline' do
        lifei_count = lifei.data_lists.count # 这个要写在前面，否则数据不会创建
        all_count = DataList.count
        public_count = DataList.public_timeline.length

        all_count.should_not == 0
        lifei_count.should_not == 0
        public_count.should_not == 0

        lifei_count.should == public_count+2

        data_list = lifei.data_lists.last
        data_list.update_attributes :public => false

        DataList.public_timeline.length.should == public_count - 1 # 将一条改为不共享，公开的少了一条

        ben7th.data_lists.create :title => '测试', :kind => 'COLLECTION', :public => true
        ben7th.data_lists.create :title => '测试', :kind => 'COLLECTION', :public => false

        DataList.count.should == all_count + 2
        DataList.public_timeline.length.should == public_count # 又创建了一条公开的，数量和原来又一样了
      end

      it 'public_timeline 以修改时间排序' do
        lifei.data_lists.count.should_not == 0

        d1 = DataList.public_timeline[0]
        d2 = DataList.public_timeline[1]

        (d1.updated_at > d2.updated_at).should == true

        Timecop.travel(Time.now + 1.hours)
        d2.create_item('URL', 'ben7th的微博', 'http://weibo.com/ben7th')

        DataList.public_timeline[0].should == d2
        DataList.public_timeline[1].should == d1
      end

      it '用户可以收藏(watch)其他人的列表，且反复watch一个列表不会重复创建watch记录' do
        lifei.data_lists.count.should_not == 0
        ben7th.data_lists.count.should == 2

        ben7th.watched_list.length.should == 0
        ben7th.watch lifei.data_lists[0]
        ben7th.reload
        ben7th.watched_list.length.should == 1
        ben7th.watch lifei.data_lists[0]
        ben7th.reload
        ben7th.watched_list.length.should == 1

        ben7th.watch lifei.data_lists[1]
        ben7th.reload
        ben7th.watched_list.length.should == 2

        ben7th.unwatch lifei.data_lists[1]
        ben7th.reload
        ben7th.watched_list.length.should == 1
      end
    end

  end
end