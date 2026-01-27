"""
ML Service Client - HTTP client for communicating with ML service.
"""

import os
import requests
import logging
from typing import List, Dict, Any, Optional

logger = logging.getLogger(__name__)

class MLServiceClient:
    def __init__(self, base_url: str = "http://ml-service:8000"):
        self.base_url = base_url.rstrip('/')
        self.session = requests.Session()
        self.session.timeout = 30  # 30 second timeout

    def health_check(self) -> bool:
        """Check if ML service is healthy."""
        try:
            response = self.session.get(f"{self.base_url}/health")
            return response.status_code == 200
        except Exception as e:
            logger.error(f"ML service health check failed: {e}")
            return False

    def compute_clip_similarity(self, image_data: str, text: str) -> Optional[float]:
        """
        Compute CLIP similarity between image and text.

        Args:
            image_data: Base64 encoded image data
            text: Text to compare against

        Returns:
            Similarity score (0-1) or None if failed
        """
        try:
            payload = {
                "image": image_data,
                "text": text
            }

            response = self.session.post(
                f"{self.base_url}/clip/similarity",
                json=payload
            )

            if response.status_code == 200:
                data = response.json()
                return data.get("similarity")
            else:
                logger.error(f"ML service error: {response.status_code} - {response.text}")
                return None

        except Exception as e:
            logger.error(f"Error calling ML service: {e}")
            return None

    def compute_batch_clip_similarity(self, image_data: str, texts: List[str]) -> Optional[List[float]]:
        """
        Compute CLIP similarity between image and multiple texts.

        Args:
            image_data: Base64 encoded image data
            texts: List of texts to compare against

        Returns:
            List of similarity scores or None if failed
        """
        try:
            payload = {
                "image": image_data,
                "texts": texts
            }

            response = self.session.post(
                f"{self.base_url}/clip/batch_similarity",
                json=payload
            )

            if response.status_code == 200:
                data = response.json()
                return data.get("similarities")
            else:
                logger.error(f"ML service error: {response.status_code} - {response.text}")
                return None

        except Exception as e:
            logger.error(f"Error calling ML service: {e}")
            return None

    def compute_image_similarity(self, image1_data: str, image2_data: str) -> Optional[float]:
        """
        Compute CLIP similarity between two images.

        Args:
            image1_data: Base64 encoded image data for first image
            image2_data: Base64 encoded image data for second image

        Returns:
            Similarity score (0-1) or None if failed
        """
        try:
            payload = {
                "image1": image1_data,
                "image2": image2_data
            }

            response = self.session.post(
                f"{self.base_url}/clip/image_similarity",
                json=payload
            )

            if response.status_code == 200:
                data = response.json()
                return data.get("similarity")
            else:
                logger.error(f"ML service error: {response.status_code} - {response.text}")
                return None

        except Exception as e:
            logger.error(f"Error calling ML service: {e}")
            return None

    def compute_image_similarity(self, image1_data: str, image2_data: str) -> Optional[float]:
        """
        Compute CLIP similarity between two images.

        Args:
            image1_data: Base64 encoded first image data
            image2_data: Base64 encoded second image data

        Returns:
            Similarity score (0-1) or None if failed
        """
        try:
            payload = {
                "image1": image1_data,
                "image2": image2_data
            }

            response = self.session.post(
                f"{self.base_url}/clip/image_similarity",
                json=payload
            )

            if response.status_code == 200:
                data = response.json()
                return data.get("similarity")
            else:
                logger.error(f"ML service error: {response.status_code} - {response.text}")
                return None

        except Exception as e:
            logger.error(f"Error calling ML service: {e}")
            return None

# Global client instance
_ml_client = None

def get_ml_client() -> MLServiceClient:
    """Get or create ML service client."""
    global _ml_client
    if _ml_client is None:
        # Use environment variable or default
        ml_service_url = os.getenv('ML_SERVICE_URL', 'http://ml-service:8000')
        _ml_client = MLServiceClient(ml_service_url)
    return _ml_client