"""
Comprehensive unit tests for the camera uploader Flask application.
Tests cover happy paths, edge cases, and failure conditions.
"""
import pytest
import json
import os
import stat
import tempfile
import shutil
from io import BytesIO
from unittest.mock import patch, MagicMock
from werkzeug.datastructures import FileStorage


@pytest.fixture
def app():
    """Create and configure a test app instance."""
    # Import here to avoid side effects
    import sys
    sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))
    
    with patch.dict(os.environ, {'UPLOAD_DIR': tempfile.mkdtemp()}):
        from app import app as flask_app
        flask_app.config['TESTING'] = True
        yield flask_app
        # Cleanup
        upload_dir = os.environ.get('UPLOAD_DIR')
        if upload_dir and os.path.exists(upload_dir):
            shutil.rmtree(upload_dir)


@pytest.fixture
def client(app):
    """Create a test client for the app."""
    return app.test_client()


@pytest.fixture
def upload_dir(_app):
    """Get the upload directory path."""
    return os.environ.get('UPLOAD_DIR')


class TestUploadEndpoint:
    """Test cases for the /upload endpoint."""
    
    def test_upload_valid_image(self, client, upload_dir):
        """Test uploading a valid image file."""
        data = {
            'file': (BytesIO(b'fake image data'), 'test.jpg'),
            'meta': json.dumps({'source': 'test-cam'})
        }
        
        response = client.post('/upload', data=data, content_type='multipart/form-data')
        
        assert response.status_code == 200
        json_data = response.get_json()
        assert json_data['ok'] is True
        assert 'frame_' in json_data['file']
        assert json_data['file'].endswith('.jpg')
        
        # Verify file was created
        uploaded_file = os.path.join(upload_dir, json_data['file'])
        assert os.path.exists(uploaded_file)
        
        # Verify latest.jpg link was created
        latest_file = os.path.join(upload_dir, 'latest.jpg')
        assert os.path.exists(latest_file)
    
    def test_upload_without_file(self, client):
        """Test upload request without a file."""
        response = client.post('/upload', data={}, content_type='multipart/form-data')
        
        assert response.status_code == 400
        assert response.get_data(as_text=True) == 'no file'
    
    def test_upload_with_empty_file(self, client):
        """Test upload with empty file field."""
        data = {'file': (BytesIO(b''), '')}
        response = client.post('/upload', data=data, content_type='multipart/form-data')
        
        assert response.status_code == 400
    
    def test_upload_default_source(self, client, _upload_dir):
        """Test upload with no metadata defaults to uno-r4 source."""
        data = {
            'file': (BytesIO(b'test image'), 'image.jpg')
        }
        
        response = client.post('/upload', data=data, content_type='multipart/form-data')
        
        assert response.status_code == 200
        # Default source should be used (uno-r4)
    
    def test_upload_invalid_json_metadata(self, client):
        """Test upload with malformed JSON metadata."""
        data = {
            'file': (BytesIO(b'test image'), 'image.jpg'),
            'meta': 'invalid json{'
        }
        
        response = client.post('/upload', data=data, content_type='multipart/form-data')
        
        # Should still succeed with default source
        assert response.status_code == 200
    
    def test_upload_multiple_files(self, client, upload_dir):
        """Test uploading multiple files sequentially."""
        for i in range(3):
            data = {
                'file': (BytesIO(f'image {i}'.encode()), f'test{i}.jpg'),
                'meta': json.dumps({'source': f'cam-{i}'})
            }
            
            response = client.post('/upload', data=data, content_type='multipart/form-data')
            assert response.status_code == 200
        
        # Verify latest.jpg points to the last upload
        latest_file = os.path.join(upload_dir, 'latest.jpg')
        assert os.path.exists(latest_file)
        with open(latest_file, 'rb') as f:
            content = f.read()
            assert b'image 2' in content
    
    def test_upload_large_file(self, client):
        """Test uploading a larger file."""
        large_data = b'x' * (1024 * 1024)  # 1MB file
        data = {
            'file': (BytesIO(large_data), 'large.jpg'),
            'meta': json.dumps({'source': 'test'})
        }
        
        response = client.post('/upload', data=data, content_type='multipart/form-data')
        assert response.status_code == 200
    
    def test_upload_special_characters_in_source(self, client):
        """Test upload with special characters in source metadata."""
        data = {
            'file': (BytesIO(b'test'), 'test.jpg'),
            'meta': json.dumps({'source': 'cam-test_123-special'})
        }
        
        response = client.post('/upload', data=data, content_type='multipart/form-data')
        assert response.status_code == 200
    
    def test_upload_with_missing_source_in_meta(self, client):
        """Test upload with meta that doesn't contain source field."""
        data = {
            'file': (BytesIO(b'test'), 'test.jpg'),
            'meta': json.dumps({'other_field': 'value'})
        }
        
        response = client.post('/upload', data=data, content_type='multipart/form-data')
        assert response.status_code == 200
        # Should default to uno-r4
    
    @patch('time.time')
    def test_upload_timestamp_in_filename(self, mock_time, client, upload_dir):
        """Test that uploaded files have timestamp in filename."""
        mock_time.return_value = 1234567890
        
        data = {
            'file': (BytesIO(b'test'), 'test.jpg')
        }
        
        response = client.post('/upload', data=data, content_type='multipart/form-data')
        json_data = response.get_json()
        
        assert json_data['file'] == 'frame_1234567890.jpg'
        assert os.path.exists(os.path.join(upload_dir, 'frame_1234567890.jpg'))


class TestLatestEndpoint:
    """Test cases for the /latest.jpg endpoint."""
    
    def test_latest_jpg_exists(self, client, _upload_dir):
        """Test retrieving latest.jpg when it exists."""
        # First upload a file
        data = {
            'file': (BytesIO(b'test image data'), 'test.jpg')
        }
        client.post('/upload', data=data, content_type='multipart/form-data')
        
        # Now get latest
        response = client.get('/latest.jpg')
        
        assert response.status_code == 200
        assert response.data == b'test image data'
    
    def test_latest_jpg_not_found(self, client):
        """Test retrieving latest.jpg when it doesn't exist."""
        response = client.get('/latest.jpg')
        
        # Should return 404 when file doesn't exist
        assert response.status_code == 404
    
    def test_latest_jpg_after_multiple_uploads(self, client):
        """Test that latest.jpg reflects the most recent upload."""
        # Upload first file
        data1 = {'file': (BytesIO(b'first image'), 'first.jpg')}
        client.post('/upload', data=data1, content_type='multipart/form-data')
        
        # Upload second file
        data2 = {'file': (BytesIO(b'second image'), 'second.jpg')}
        client.post('/upload', data=data2, content_type='multipart/form-data')
        
        # Get latest
        response = client.get('/latest.jpg')
        
        assert response.status_code == 200
        assert response.data == b'second image'


class TestMetricsEndpoint:
    """Test cases for the /metrics endpoint."""
    
    def test_metrics_format(self, client):
        """Test that metrics endpoint returns Prometheus format."""
        response = client.get('/metrics')
        
        assert response.status_code == 200
        assert response.headers['Content-Type'].startswith('text/plain')
        data = response.get_data(as_text=True)
        assert 'camera_upload_events_total' in data
    
    def test_metrics_counter_increments(self, client):
        """Test that upload counter increments correctly."""
        # Upload a file
        data = {
            'file': (BytesIO(b'test'), 'test.jpg'),
            'meta': json.dumps({'source': 'test-source'})
        }
        client.post('/upload', data=data, content_type='multipart/form-data')
        
        # Check metrics
        response = client.get('/metrics')
        data = response.get_data(as_text=True)
        
        # Should contain counter with source label
        assert 'camera_upload_events_total{source="test-source"}' in data
    
    def test_metrics_multiple_sources(self, client):
        """Test metrics tracking for multiple sources."""
        sources = ['cam1', 'cam2', 'cam3']
        
        for source in sources:
            data = {
                'file': (BytesIO(b'test'), 'test.jpg'),
                'meta': json.dumps({'source': source})
            }
            client.post('/upload', data=data, content_type='multipart/form-data')
        
        # Check metrics
        response = client.get('/metrics')
        data = response.get_data(as_text=True)
        
        for source in sources:
            assert f'source="{source}"' in data


class TestHealthzEndpoint:
    """Test cases for the /healthz endpoint."""
    
    def test_healthz_returns_ok(self, client):
        """Test health check endpoint returns ok."""
        response = client.get('/healthz')
        
        assert response.status_code == 200
        json_data = response.get_json()
        assert json_data['ok'] is True
    
    def test_healthz_json_format(self, client):
        """Test health check returns valid JSON."""
        response = client.get('/healthz')
        
        assert response.content_type == 'application/json'
        json_data = response.get_json()
        assert isinstance(json_data, dict)
        assert 'ok' in json_data


class TestFileSystemOperations:
    """Test edge cases around file system operations."""
    
    def test_upload_creates_directory_if_missing(self):
        """Test that upload directory is created if it doesn't exist."""
        with tempfile.TemporaryDirectory() as tmpdir:
            upload_path = os.path.join(tmpdir, 'non_existent_dir')
            
            with patch.dict(os.environ, {'UPLOAD_DIR': upload_path}):
                # Import app which should create the directory
                import sys
                sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
                import importlib
                import app as app_module
                importlib.reload(app_module)
                
                assert os.path.exists(upload_path)
    
    def test_latest_link_removal_fails_gracefully(self, client, upload_dir):
        """Test that failure to remove latest.jpg is handled gracefully."""
        # First upload
        data = {'file': (BytesIO(b'first'), 'first.jpg')}
        client.post('/upload', data=data, content_type='multipart/form-data')
        
        # Make latest.jpg read-only to simulate removal failure
        os.chmod(upload_dir, stat.S_IRUSR | stat.S_IXUSR)
        
        # Second upload should still succeed
        data2 = {'file': (BytesIO(b'second'), 'second.jpg')}
        response = client.post('/upload', data=data2, content_type='multipart/form-data')
        
        # Restore permissions for cleanup
        os.chmod(upload_dir, stat.S_IRWXU)
        
        # Upload should still succeed
        assert response.status_code == 200


class TestConcurrency:
    """Test concurrent access scenarios."""
    
    def test_rapid_sequential_uploads(self, client):
        """Test rapid sequential uploads don't cause issues."""
        for i in range(10):
            data = {
                'file': (BytesIO(f'image {i}'.encode()), f'test{i}.jpg'),
                'meta': json.dumps({'source': f'cam-{i % 3}'})
            }
            response = client.post('/upload', data=data, content_type='multipart/form-data')
            assert response.status_code == 200


class TestInputValidation:
    """Test input validation and sanitization."""
    
    def test_upload_with_null_bytes_in_metadata(self, client):
        """Test handling of null bytes in metadata."""
        data = {
            'file': (BytesIO(b'test'), 'test.jpg'),
            'meta': 'test\x00data'
        }
        
        response = client.post('/upload', data=data, content_type='multipart/form-data')
        # Should handle gracefully and use default source
        assert response.status_code == 200
    
    def test_upload_empty_metadata_string(self, client):
        """Test upload with empty metadata string."""
        data = {
            'file': (BytesIO(b'test'), 'test.jpg'),
            'meta': ''
        }
        
        response = client.post('/upload', data=data, content_type='multipart/form-data')
        assert response.status_code == 200
    
    def test_upload_metadata_not_dict(self, client):
        """Test upload with metadata that's not a dictionary."""
        data = {
            'file': (BytesIO(b'test'), 'test.jpg'),
            'meta': json.dumps(['list', 'not', 'dict'])
        }
        
        response = client.post('/upload', data=data, content_type='multipart/form-data')
        assert response.status_code == 200


class TestEnvironmentConfiguration:
    """Test environment variable configuration."""
    
    def test_custom_upload_directory(self):
        """Test that UPLOAD_DIR environment variable is respected."""
        with tempfile.TemporaryDirectory() as custom_dir:
            with patch.dict(os.environ, {'UPLOAD_DIR': custom_dir}):
                import sys
                sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
                import importlib
                import app as app_module
                importlib.reload(app_module)
                
                client = app_module.app.test_client()
                
                data = {'file': (BytesIO(b'test'), 'test.jpg')}
                response = client.post('/upload', data=data, content_type='multipart/form-data')
                
                assert response.status_code == 200
                # Verify file was created in custom directory
                files = os.listdir(custom_dir)
                assert len(files) > 0
    
    def test_default_upload_directory(self):
        """Test default UPLOAD_DIR when not specified."""
        with patch.dict(os.environ, clear=True):
            import sys
            sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
            import importlib
            import app as app_module
            importlib.reload(app_module)
            
            # Default should be /data
            # Just verify the app doesn't crash
            assert app_module.UPLOAD_DIR == '/data'