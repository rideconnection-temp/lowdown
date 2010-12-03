require 'test_helper'

class VersionFuTest < ActiveSupport::TestCase
   #############################################################################
   #                         A S S O C I A T I O N S                           #
   #############################################################################
   test 'parent has many versions' do
    page = pages(:welcome)
    assert_equal pages(:welcome_1, :welcome), pages(:welcome).versions 
   end
  
   test 'version belongs to parent' do
     assert_equal pages(:welcome), pages(:welcome_1).versions.last
   end

   test 'current versions works' do
     assert_equal 1, Author.old_versions.all.count
     assert_equal 3, Author.current_versions.all.count
   end

   #############################################################################
   #                               C R E A T E                                 #
   #############################################################################
   test 'save version on create' do
     old_count = Page.count
     old_version_count = Page.old_versions.count
     page = Page.create :title=>'New', :body=>'body', :creator=>authors(:larry), :author=>authors(:larry)
     assert_equal old_count + 1, Page.count
     assert_equal old_version_count, Page.old_versions.count
   end
  
   test 'wire up associations on create' do
     page = Page.create :title=>'New', :body=>'body', :creator=>authors(:larry), :author=>authors(:larry)
     assert_equal Page.find(:first, :order=>'valid_start desc'), page.versions.first
   end
  
   test 'begin valid_start at now' do
     page = Page.create :title=>'New', :body=>'body', :creator=>authors(:larry), :author=>authors(:larry)
     assert Time.now - page.valid_start < 1
     assert_equal page.valid_end, page.end_of_time
   end
  
   test 'assign attributes on create' do
     page = Page.create :title=>'New', :body=>'body', :creator=>authors(:larry), :author=>authors(:larry)

     version = page.versions.first
     assert_equal 'New', version.title
     assert_equal 'body', version.body
     assert_equal authors(:larry).id, version.author_id
   end
  
   #############################################################################
   #                                   U P D A T E                             #
   #############################################################################
    test 'save version on update' do
      old_count = Page.old_versions.count
      page = pages(:welcome)
      page.update_attributes :title=>'New title', :body=>'new body', :author=>authors(:sara)
      assert_equal old_count + 1, Page.old_versions.count
    end
  
   test 'valid dates sane' do    
     page = pages(:welcome).versions.latest

     old_end = page.valid_end 
     assert_equal page.end_of_time, old_end
     page.update_attributes :title=>'New title', :body=>'new body', :author=>authors(:sara)
     assert_equal old_end, page.valid_end

     assert_in_delta Time.now, page.valid_start, 1
     new_prev = page.previous

     assert_equal new_prev.valid_end, page.valid_start

   end
  
   test 'update version attributes' do
     page = pages(:welcome)
     page.update_attributes :title=>'Latest', :body=>'newest', :author=>authors(:peter)
     version = page.reload.versions.latest
     assert_equal 'Latest', version.title
     assert_equal 'newest', version.body
     assert_equal authors(:peter).id, version.author_id
   end
  
#   #############################################################################
#   #                         S K I P    V E R S I O N I N G                    #
#   #############################################################################
   test 'do not create version if nothing changed' do
     old_count = Page.old_versions.count
     pages(:welcome).save
     assert_equal old_count, Page.old_versions.count
   end  
  
   test 'do not create version if untracked attribute changed' do
     old_count = Page.old_versions.count
     pages(:welcome).update_attributes :author=>authors(:sara)
     assert_equal old_count, Page.old_versions.count
   end

   test 'do not create version if custom version check' do
     old_count = Author.old_versions.count
     authors(:larry).update_attributes :last_name=>'Lessig'
     assert_equal old_count, Author.old_versions.count
   end

   test 'still save if no new version with custom version check' do
     authors(:larry).update_attributes :last_name=>'Lessig'
     assert_equal 'Lessig', authors(:larry).reload.last_name
   end
  
   #############################################################################
   #                                 F I N D                                   #
   #############################################################################
   test 'find version given date' do
     assert_equal pages(:welcome_1), pages(:welcome).find_version(Time.xmlschema('2010-10-11T12:00:00Z'))
     assert_equal pages(:welcome), pages(:welcome).find_version(Time.now)
   end
  
   test 'find latest version' do
     assert_equal pages(:welcome), pages(:welcome_1).versions.latest
   end
  
   test 'find previous version' do
     assert_equal pages(:welcome_1), pages(:welcome).previous
   end
  
   test 'find next version' do
      assert_equal pages(:welcome), pages(:welcome_1).next
   end
  
#   #############################################################################
#   #                        B L O C K    E X T E N S I O N                     #
#   #############################################################################
   test 'take a block containing ActiveRecord extension' do
     assert_equal authors(:larry), pages(:welcome_1).author
   end
end
